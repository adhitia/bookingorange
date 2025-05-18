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
    if params[:branch_id].present?
      @branch = Branch.find(params[:branch_id])
    else
      @branch = Branch.first
    end

    # Rentang waktu tampilan, misalnya 08:00 sampai 20:00 tiap 30 menit
    start_display = Time.zone.parse("2000-01-01 10:00")
    end_display   = Time.zone.parse("2000-01-01 20:00")
    @time_slots = []
    current = start_display
    while current < end_display
      @time_slots << current.strftime("%H:%M")
      current += 30.minutes
    end

    # Hari dalam seminggu (dalam Bahasa Indonesia)
    @week_days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]

    # Buat lookup jadwal untuk setiap slot dalam rentang setiap hari
    # (Menampilkan semua schedule untuk cabang tersebut; jika satu slot memiliki lebih dari satu jadwal, simpan dalam array)
    @schedule_lookup = {}
    @branch.schedules.includes(:doctor).each do |s|
      # Ubah waktu mulai dan akhir schedule menjadi objek Time dengan tanggal dummy "2000-01-01"
      sched_start = Time.zone.parse("2000-01-01 #{s.start_time.strftime('%H:%M')}")
      sched_end   = Time.zone.parse("2000-01-01 #{s.end_time.strftime('%H:%M')}")
      current_slot = sched_start
      while current_slot < sched_end
        key = [s.day, current_slot.strftime("%H:%M")]
        @schedule_lookup[key] ||= []
        @schedule_lookup[key] << s
        current_slot += 30.minutes
      end
    end
  end
  

  private

  def set_branch
    @branch = Branch.find(params[:id])
  end

  def branch_params
    params.require(:branch).permit(:name, :location, :phone)
  end

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Anda tidak memiliki akses untuk area ini."
      redirect_to root_path
    end
  end
end
