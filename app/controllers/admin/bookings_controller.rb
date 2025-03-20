class Admin::BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    # Default filter: booking dibuat hari ini (created_at)
    start_of_today = Date.today.beginning_of_day
    end_of_today   = Date.today.end_of_day
    @bookings = Booking.where(created_at: start_of_today..end_of_today)

    # Filter berdasarkan booking_date jika ada
    if params[:booking_date].present?
      booking_date = Date.parse(params[:booking_date]) rescue nil
      @bookings = @bookings.where(booking_date: booking_date) if booking_date
    end

    # Filter berdasarkan created_at jika ada (misal, untuk tanggal tertentu)
    if params[:created_at].present?
      created_date = Date.parse(params[:created_at]) rescue nil
      if created_date
        @bookings = @bookings.where(created_at: created_date.beginning_of_day..created_date.end_of_day)
      end
    end

    # Filter berdasarkan cabang
    if params[:branch_id].present?
      @bookings = @bookings.where(branch_id: params[:branch_id])
    end

    # Filter berdasarkan status
    if params[:status].present?
      @bookings = @bookings.where(status: params[:status])
    end

    # Urutkan berdasarkan created_at descending dan paginasi
    @bookings = @bookings.order(created_at: :desc).page(params[:page]).per(20)
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
