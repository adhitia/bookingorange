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

  def destroy
    @doctor.destroy
    flash[:notice] = "Dokter berhasil dihapus."
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
