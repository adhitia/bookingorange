class Admin::DoctorsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_doctor, only: [:show, :edit, :update, :destroy]

  def index
    @doctors = Doctor.all
  end

  def new
    @doctor = Doctor.new
  end

  def create
    @doctor = Doctor.new(doctor_params)
    if @doctor.save
      flash[:notice] = "Dokter berhasil dibuat."
      redirect_to admin_doctors_path
    else
      flash.now[:alert] = "Gagal membuat dokter."
      render :new
    end
  end

  def edit
  end

  def update
    if @doctor.update(doctor_params)
      flash[:notice] = "Dokter berhasil diupdate."
      redirect_to admin_doctors_path
    else
      flash.now[:alert] = "Gagal mengupdate dokter."
      render :edit
    end
  end

   # Action destroy: jika parameter fallback belum ada, render form confirm_destroy
   def destroy
    if params[:fallback_doctor_id].present?
      perform_destroy
    else
      @fallback_options = Doctor.where.not(id: @doctor.id)
      render :confirm_destroy
    end
  end

  # Action untuk benar-benar menghapus dokter setelah fallback dipilih
  def perform_destroy
    fallback_doctor = Doctor.find(params[:fallback_doctor_id])
    
    # Reassign schedules ke fallback doctor
    @doctor.schedules.update_all(doctor_id: fallback_doctor.id)
    # Reassign bookings ke fallback doctor (agar tidak ada foreign key violation)
    Booking.where(doctor_id: @doctor.id).update_all(doctor_id: fallback_doctor.id)
    
    if @doctor.destroy
      flash[:notice] = "Dokter berhasil dihapus dan jadwal serta booking telah dialihkan ke #{fallback_doctor.name}."
    else
      flash[:alert] = "Gagal menghapus dokter."
    end
    redirect_to admin_doctors_path
  end

  private

  def set_doctor
    @doctor = Doctor.find(params[:id])
  end

  def doctor_params
    params.require(:doctor).permit(:name, :branch_id)
  end

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Anda tidak memiliki akses untuk area ini."
      redirect_to root_path
    end
  end
end
