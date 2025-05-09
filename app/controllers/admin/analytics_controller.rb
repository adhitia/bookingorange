class Admin::AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  def bookings
    @branches = Branch.all
  
    # Filter berdasarkan tanggal created_at, default 7 hari terakhir
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 7.days.ago.to_date
    @end_date   = params[:end_date].present?   ? Date.parse(params[:end_date])   : Date.today
    @branch_id  = params[:branch_id]
    @tipe_booking = params[:tipe_booking]

    # Ambil booking berdasarkan created_at dalam rentang waktu lokal (asumsi disimpan sebagai local time)
    if @tipe_booking.blank?
      bookings = Booking.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).where.not(tipe_booking: :non_patient)
    else
      bookings = Booking.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day, tipe_booking: @tipe_booking)
    end
    
    bookings = bookings.where(branch_id: @branch_id) if @branch_id.present?
  
    # Gunakan query grouping manual dengan SQL function DATE(created_at)
    @total_booking = bookings.group("DATE(created_at)").count
  
    # Asumsikan user memiliki enum role: { admin: 0, customer_service: 1, staff_cabang: 2 }
    cs_ids = User.where(role: :customer_service).pluck(:id)
    staff_ids = User.where(role: :staff_cabang).pluck(:id)
  
    @booking_cs = bookings.where(created_by_id: cs_ids).group("DATE(created_at)").count
    @booking_staff = bookings.where(created_by_id: staff_ids).group("DATE(created_at)").count
  
    # Ubah hasil grouping menjadi format array untuk Chartkick, misalnya:
    @chart_total = @total_booking.sort_by { |date, _| date }.map { |date, count| [date, count] }
    @chart_cs = @booking_cs.sort_by { |date, _| date }.map { |date, count| [date, count] }
    @chart_staff = @booking_staff.sort_by { |date, _| date }.map { |date, count| [date, count] }
  end

  private

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Akses hanya untuk admin."
      redirect_to root_path
    end
  end
end