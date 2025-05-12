class Admin::AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  def bookings
    @branches    = Branch.all
    @start_date  = params[:start_date].present? ? Date.parse(params[:start_date]) : 7.days.ago.to_date
    @end_date    = params[:end_date].present?   ? Date.parse(params[:end_date])   : Date.today
    @branch_id   = params[:branch_id]
    @tipe_booking = params[:tipe_booking]

    # Build base scope dengan filter tanggal, tipe_booking, dan cabang
    base_scope = Booking.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
    base_scope = if @tipe_booking.blank?
                    base_scope.where.not(tipe_booking: :non_patient)
                  else
                    base_scope.where(tipe_booking: @tipe_booking)
                  end
    base_scope = base_scope.where(branch_id: @branch_id) if @branch_id.present?

    # Total keseluruhan per tanggal
    @total_booking = base_scope.group("DATE(created_at)").count

    # Ambil nama user per role
    cs_users    = User.where(role: :customer_service).pluck(:id, :name).to_h
    staff_users = User.where(role: :staff_cabang).pluck(:id, :name).to_h

    # Hitung grouping per tanggal + user
    cs_grouped = base_scope.where(created_by_id: cs_users.keys)
                           .group("DATE(created_at)", :created_by_id)
                           .count
    staff_grouped = base_scope.where(created_by_id: staff_users.keys)
                              .group("DATE(created_at)", :created_by_id)
                              .count

    # Bangun breakdown { date => [[name, count], …] }
    @cs_breakdown    = Hash.new { |h,k| h[k] = [] }
    cs_grouped.each    { |(d,u),c| @cs_breakdown[d]    << [ cs_users[u],    c ] }

    @staff_breakdown = Hash.new { |h,k| h[k] = [] }
    staff_grouped.each { |(d,u),c| @staff_breakdown[d] << [ staff_users[u], c ] }

    # Data untuk Chartkick
    @chart_total  = @total_booking.sort.map { |d,c| [d, c] }
    @chart_cs     = @cs_breakdown.map    { |d,arr| [d, arr.sum { |_,cnt| cnt }] }.sort_by(&:first)
    @chart_staff  = @staff_breakdown.map { |d,arr| [d, arr.sum { |_,cnt| cnt }] }.sort_by(&:first)
    
    # Asumsikan user memiliki enum role: { admin: 0, customer_service: 1, staff_cabang: 2 }
    cs_ids = User.where(role: :customer_service).pluck(:id)
    staff_ids = User.where(role: :staff_cabang).pluck(:id)
    @booking_cs = base_scope.where(created_by_id: cs_ids).group("DATE(created_at)").count
    @booking_staff = base_scope.where(created_by_id: staff_ids).group("DATE(created_at)").count
  end

  private

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Akses hanya untuk admin."
      redirect_to root_path
    end
  end
end