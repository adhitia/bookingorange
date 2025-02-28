class BookingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @branches = Branch.all
    @doctors  = Doctor.all
    @statuses = Booking.statuses.keys

    if current_user.customer_service?
      # Menampilkan booking yang dibuat pada hari ini
      @bookings = Booking.where(created_at: Time.zone.today.all_day)
    else
      @bookings = Booking.all
    end

    # Filter berdasarkan cabang
    @bookings = @bookings.where(branch_id: params[:branch_id]) if params[:branch_id].present?

    # Filter berdasarkan dokter
    @bookings = @bookings.where(doctor_id: params[:doctor_id]) if params[:doctor_id].present?

    # Filter berdasarkan tanggal (berdasarkan tanggal di schedule)
    if params[:date].present?
      @bookings = @bookings.joins(:schedule).where(schedules: { date: params[:date] })
    end

    # Filter berdasarkan status booking
    @bookings = @bookings.where(status: params[:status]) if params[:status].present?

  end

  def show
    @booking = Booking.find(params[:id])
  end

  # Form booking untuk Customer Service
  def new_cs
    @branches = Branch.all
    if params[:branch_id].present? && params[:date].present?
      @selected_branch = Branch.find(params[:branch_id])
      @selected_date = Date.parse(params[:date])
      # Konversi nama hari dari tanggal ke bahasa Indonesia
      day_name = convert_to_indonesian(@selected_date.strftime("%A"))
      
      # Ambil semua jadwal rutin untuk cabang dan hari tersebut
      schedules = @selected_branch.schedules.where(day: day_name)
      
      @available_slots = []
      booking_duration = 30.minute  # Durasi booking 1 jam
      schedules.each do |schedule|
        slot_time = schedule.start_time
        # Generate slot selama slot_time + booking_duration tidak melebihi end_time
        while slot_time + booking_duration <= schedule.end_time
          # Cek apakah untuk schedule ini, pada tanggal dan waktu slot tersebut sudah ada booking
          unless Booking.exists?(schedule_id: schedule.id, booking_date: @selected_date, booking_time: slot_time)
            @available_slots << { schedule: schedule, slot_time: slot_time }
          end
          slot_time += booking_duration
        end
      end
    else
      @available_slots = []
    end
    @booking = Booking.new
  end
  

  # Proses pembuatan booking oleh Customer Service
  def create_cs
    bp = booking_params
    slot_combined = bp.delete(:slot_combined)
    @booking = Booking.new(bp)
    
    if slot_combined.present?
      schedule_id, slot_str = slot_combined.split("|")
      schedule = Schedule.find(schedule_id)
      @booking.schedule = schedule
      @booking.booking_time = Time.parse(slot_str)
      # Assign dokter berdasarkan schedule yang dipilih
      @booking.doctor = schedule.doctor
      @booking.customer_name = params[:customer_name]
      @booking.customer_phone = params[:customer_phone] 
    end
    @booking.created_by = current_user
    @booking.status = 0  # Status scheduled
    if @booking.save
      flash[:notice] = "Booking berhasil dibuat."
      redirect_to bookings_path
    else
      flash.now[:alert] = "Gagal membuat booking."
      new_cs
      render :new_cs
    end
  end
  
  

  private

  def booking_params
    params.require(:booking).permit(:branch_id, :booking_date, :customer_name, :customer_phone, :slot_combined)
  end

  # Konversi nama hari dari bahasa Inggris ke Bahasa Indonesia
  def convert_to_indonesian(day_name)
    mapping = {
      "Monday"    => "Senin",
      "Tuesday"   => "Selasa",
      "Wednesday" => "Rabu",
      "Thursday"  => "Kamis",
      "Friday"    => "Jumat",
      "Saturday"  => "Sabtu",
      "Sunday"    => "Minggu"
    }
    mapping[day_name] || day_name
  end

  def authorize_customer_service
    unless current_user.customer_service?
      flash[:alert] = "Akses hanya untuk Customer Service."
      redirect_to root_path
    end
  end
end
