class Admin::BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_booking, only: [:show, :edit, :update, :destroy]

  def index
    @bookings = Booking.all.includes(:branch, :doctor, :schedule)
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
