class Admin::AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  def bookings
    @branches     = Branch.all
    @start_date   = params[:start_date].present? ? Date.parse(params[:start_date]) : 7.days.ago.to_date
    @end_date     = params[:end_date].present?   ? Date.parse(params[:end_date])   : Date.today
    @branch_id    = params[:branch_id]
    @tipe_booking = params[:tipe_booking]
  
    base_scope = Booking
                   .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                   .yield_self { |s| @tipe_booking.blank? ? s.where.not(tipe_booking: :non_patient) : s.where(tipe_booking: @tipe_booking) }
    base_scope = base_scope.where(branch_id: @branch_id) if @branch_id.present?
  
    # total per tanggal
    @total_booking = base_scope.group("DATE(created_at)").count
  
    # ambil user id/ nama per role
    cs_users    = User.where(role: :customer_service).pluck(:id, :name).to_h
    staff_users = User.where(role: :staff_cabang).pluck(:id, :name).to_h
  
    # group per tanggal + user_id
    cs_grouped    = base_scope.where(created_by_id: cs_users.keys)
                              .group("DATE(created_at)", :created_by_id)
                              .count
    staff_grouped = base_scope.where(created_by_id: staff_users.keys)
                              .group("DATE(created_at)", :created_by_id)
                              .count
  
    # bangun struktur breakdown: { date => [[name, count], …] }
    @cs_breakdown    = Hash.new { |h,k| h[k] = [] }
    cs_grouped.each do |(date, uid), cnt|
      @cs_breakdown[date] << [ cs_users[uid], cnt ]
    end
  
    @staff_breakdown = Hash.new { |h,k| h[k] = [] }
    staff_grouped.each do |(date, uid), cnt|
      @staff_breakdown[date] << [ staff_users[uid], cnt ]
    end
  
    # untuk Chartkick
    @chart_total  = @total_booking.sort_by { |d,_| d }.map { |d,c| [d,c] }
    @chart_cs     = cs_grouped.group_by { |(d,_),_| d }
                              .map { |d,pairs| [d, pairs.sum{ |_,c| c }] }
                              .sort_by(&:first)
    @chart_staff  = staff_grouped.group_by { |(d,_),_| d }
                              .map { |d,pairs| [d, pairs.sum{ |_,c| c }] }
                              .sort_by(&:first)
  end

  private

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Akses hanya untuk admin."
      redirect_to root_path
    end
  end
end