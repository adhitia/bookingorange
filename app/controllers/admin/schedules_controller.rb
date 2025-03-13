class Admin::SchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_schedule, only: [:show, :edit, :update, :destroy]

  def index
    @schedules = Schedule.all.includes(:doctor, :branch)
  end

  def new
    @schedule = Schedule.new
  end

  def create
    @schedule = Schedule.new(schedule_params)
    if @schedule.save
      flash[:notice] = "Jadwal berhasil dibuat."
      redirect_to admin_schedules_path
    else
      flash.now[:alert] = "Gagal membuat jadwal."
      render :new
    end
  end

  def edit
  end

  def update
    if @schedule.update(schedule_params)
      flash[:notice] = "Jadwal berhasil diupdate."
      redirect_to admin_schedules_path
    else
      flash.now[:alert] = "Gagal mengupdate jadwal."
      render :edit
    end
  end

  def destroy
    if @schedule.destroy
      flash[:notice] = "Jadwal dokter berhasil dihapus."
    else
      flash[:alert] = "Gagal menghapus jadwal dokter."
    end
    redirect_to admin_schedules_path
  end

  private

  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  def schedule_params
    params.require(:schedule).permit(:branch_id, :doctor_id, :day, :start_time, :end_time)
  end

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Anda tidak memiliki akses untuk area ini."
      redirect_to root_path
    end
  end
end
