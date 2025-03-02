class Admin::BranchesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_branch, only: [:show, :edit, :update, :destroy]

  def index
    @branches = Branch.all
  end

  def new
    @branch = Branch.new
  end

  def create
    @branch = Branch.new(branch_params)
    if @branch.save
      flash[:notice] = "Cabang berhasil dibuat."
      redirect_to admin_branches_path
    else
      flash.now[:alert] = "Gagal membuat cabang."
      render :new
    end
  end

  def edit
  end

  def update
    if @branch.update(branch_params)
      flash[:notice] = "Cabang berhasil diupdate."
      redirect_to admin_branches_path
    else
      flash.now[:alert] = "Gagal mengupdate cabang."
      render :edit
    end
  end

  def destroy
    @branch.destroy
    flash[:notice] = "Cabang berhasil dihapus."
    redirect_to admin_branches_path
  end

  def timetable
    @branch = Branch.find(params[:id])
    
    # Tentukan rentang waktu kalender untuk tampilan timetable.
    # Misal, dari 08:00 sampai 20:00, setiap 30 menit.
    start_display = Time.zone.parse("2000-01-01 10:00")
    end_display   = Time.zone.parse("2000-01-01 20:00")
    @time_slots = []
    current = start_display
    while current <= end_display
      @time_slots << current.strftime("%H:%M")
      current += 30.minutes
    end
  
    # Daftar hari dalam seminggu
    @week_days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
  
    # Buat lookup hash untuk semua slot dalam jadwal praktik di cabang ini.
    # Key-nya: [hari, "HH:MM"], value-nya adalah schedule.
    @schedule_lookup = {}
    @branch.schedules.includes(:doctor).each do |s|
      # Ambil waktu mulai dan akhir schedule sebagai objek waktu dengan tanggal dummy
      sched_start = Time.zone.parse("2000-01-01 #{s.start_time.strftime('%H:%M')}")
      sched_end   = Time.zone.parse("2000-01-01 #{s.end_time.strftime('%H:%M')}")
      slot_time = sched_start
      # Selama slot_time kurang dari sched_end (asumsikan slot harus dimulai sebelum akhir jadwal)
      while slot_time < sched_end
        key = [s.day, slot_time.strftime("%H:%M")]
        @schedule_lookup[key] = s
        slot_time += 30.minutes
      end
    end
  end

  private

  def set_branch
    @branch = Branch.find(params[:id])
  end

  def branch_params
    params.require(:branch).permit(:name, :location)
  end

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Anda tidak memiliki akses untuk area ini."
      redirect_to root_path
    end
  end
end
