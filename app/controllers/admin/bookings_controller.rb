class Admin::BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    # Ambil daftar cabang untuk dropdown filter
    @branches = Branch.all
  
    # --- Filter Created At (tanggal dibuat booking) ---
    if params[:start_created_at].present? && params[:end_created_at].present?
      start_created = Date.parse(params[:start_created_at]).beginning_of_day rescue Date.today.beginning_of_day
      end_created   = Date.parse(params[:end_created_at]).end_of_day rescue Date.today.end_of_day
    else
      # Default: hari ini
      start_created = Date.today.beginning_of_day
      end_created   = Date.today.end_of_day
    end
  
    # --- Filter Booking Date (tanggal booking sebenarnya) ---
    if params[:start_booking_date].present? && params[:end_booking_date].present?
      start_booking = Date.parse(params[:start_booking_date]) rescue nil
      end_booking   = Date.parse(params[:end_booking_date]) rescue nil
    end
  
    # Mulai query dengan filter created_at
    bookings = Booking.where(created_at: start_created..end_created)
  
    # Jika filter booking_date disediakan, tambahkan filter tersebut
    bookings = bookings.where(booking_date: start_booking..end_booking) if start_booking && end_booking
  
    # Filter berdasarkan cabang jika disediakan
    bookings = bookings.where(branch_id: params[:branch_id]) if params[:branch_id].present?
  
    # Filter berdasarkan status jika disediakan
    bookings = bookings.where(status: params[:status]) if params[:status].present?
  
    @bookings = bookings.order(created_at: :desc).page(params[:page]).per(20)
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
