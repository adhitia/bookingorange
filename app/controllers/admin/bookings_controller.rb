class Admin::BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    # Ambil daftar cabang untuk dropdown filter
    @branches = Branch.all
    @branch = params[:branch_id].present? ? Branch.find(params[:branch_id]) : Branch.last
    @branch_id = params[:branch_id]
    start_created = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today
  
    # Ambil tanggal dari hari ini sampai 6 hari ke depan (total 7 hari)
    @dates = (start_created..(start_created + 6)).to_a
            
    # Definisikan time slot tiap 30 menit dari pukul 10:00 sampai 20:00
    start_time = Time.zone.parse("#{Date.today} 10:00")
    end_time   = Time.zone.parse("#{Date.today} 20:00")
    @time_slots = []
    while start_time < end_time
        @time_slots << start_time.strftime("%H:%M")
        start_time += 30.minutes
    end
    
    # Ambil semua booking untuk branch staff dalam rentang tanggal tersebut, kecuali yang dibatalkan
    @bookings = Booking.where(branch_id: @branch_id, booking_date: start_created..(start_created + 6))
                       .where.not(status: 'canceled')
    
    # Buat lookup hash dengan key: [booking_date, booking_time_str]
    @booking_lookup = {}
    @bookings.each do |booking|
        key = [booking.booking_date, booking.booking_time.strftime("%H:%M")]
        @booking_lookup[key] = booking
    end


  end
  

  def show
  end

  def new
    @booking = Booking.new
    # Set default booking_date misalnya hari ini
    @booking.booking_date = Date.today
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.created_by = current_user
    if @booking.save
      flash[:notice] = "Booking berhasil dibuat."
      redirect_to admin_booking_path(@booking)
    else
      flash.now[:alert] = "Gagal membuat booking."
      render :new
    end
  end

  def edit
  end

  def update
    if @booking.update(booking_params)
      flash[:notice] = "Booking berhasil diubah."
      redirect_to admin_booking_path(@booking)
    else
      flash.now[:alert] = "Gagal mengubah booking."
      render :edit
    end
  end

  def destroy
    @booking.destroy
    flash[:notice] = "Booking berhasil dihapus."
    redirect_to admin_bookings_path
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:branch_id, :doctor_id, :schedule_id, :booking_date, :customer_name, :customer_phone, :status)
  end

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Anda tidak memiliki akses ke area ini."
      redirect_to root_path
    end
  end
end
