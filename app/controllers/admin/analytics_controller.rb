class Admin::AnalyticsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin
  
    def bookings
      # Ambil daftar cabang untuk dropdown filter
      @branches = Branch.all
  
      # Ambil parameter filter
      @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 7.days.ago.to_date
      @end_date   = params[:end_date].present?   ? Date.parse(params[:end_date])   : Date.today
      @branch_id  = params[:branch_id]
  
      # Ambil booking sesuai filter date range
      bookings = Booking.where(created_at: @start_date..@end_date)
  
      # Filter berdasarkan cabang jika branch_id diisi
      bookings = bookings.where(branch_id: @branch_id) if @branch_id.present?
  
      # Hitung total booking harian
      # Contoh: group by booking_date lalu count
      # Pastikan booking_date disimpan sebagai date di DB
      @daily_counts = bookings.group(:booking_date).count
  
      # Contoh: data untuk line chart (Chartkick format) -> array of [date, count]
      # sorted agar urutan x-axis berurutan
      @chart_data = @daily_counts.sort_by { |date, _| date }.map { |date, c| [date, c] }
  
      # Anda juga bisa menampilkan data di tabel @daily_counts
    end
  
    private
  
    def authorize_admin
      unless current_user.admin?
        flash[:alert] = "Akses hanya untuk admin."
        redirect_to root_path
      end
    end
  end
  