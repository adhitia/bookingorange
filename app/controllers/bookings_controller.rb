class BookingsController < ApplicationController
  before_action :authenticate_user!, except: [:register_outside, :create_register_outside]
  layout 'pendaftaran', only: [:register_outside, :create_register_outside, :thank_you_register]

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
      # Konversi nama hari ke Bahasa Indonesia
      day_name = convert_to_indonesian(@selected_date.strftime("%A"))
      
      # Ambil semua jadwal rutin untuk cabang dan hari tersebut
      schedules = @selected_branch.schedules.where(day: day_name)
      
      @available_slots = []
      # Durasi default booking adalah 30 menit
      booking_duration = 30.minutes
      schedules.each do |schedule|
        slot_time = schedule.start_time
        while slot_time + booking_duration <= schedule.end_time
          candidate_start = slot_time
          candidate_end   = slot_time + booking_duration
  
          # Cek apakah ada booking yang tumpang tindih dengan interval kandidat,
          # kecuali booking yang telah dibatalkan (status: canceled).
          conflict = Booking.where(schedule_id: schedule.id, booking_date: @selected_date)
                            .where.not(status: 'canceled')
                            .where("booking_time < ? AND booking_end_time > ?", candidate_end, candidate_start)
                            .exists?
          unless conflict
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
    bp = booking_params.except(:slot_combined)
    slot_combined = booking_params[:slot_combined]
  
    @booking = Booking.new(bp)
    # Misalnya, untuk CS, cabang diambil dari form (atau bisa juga otomatis)
    @booking.branch = Branch.find(booking_params[:branch_id]) if booking_params[:branch_id].present?
    @booking.created_by = current_user
  
    if slot_combined.present?
      schedule_id, slot_str = slot_combined.split("|")
      schedule = Schedule.find(schedule_id)
      @booking.schedule = schedule
      @booking.booking_time = Time.zone.parse(slot_str)
      @booking.doctor = schedule.doctor
    else
      @booking.errors.add(:base, "Slot harus dipilih")
      render :new_cs and return
    end
  
    # Set default booking_end_time: jika tidak diisi, set menjadi booking_time + 30 menit
    if booking_params[:booking_end_time].blank?
      @booking.booking_end_time = @booking.booking_time + 30.minutes
    else
      @booking.booking_end_time = Time.zone.parse(booking_params[:booking_end_time])
    end
    
    @booking.status = :scheduled

    if @booking.save
      flash[:notice] = "Booking berhasil dibuat."
      redirect_to booking_path(@booking)
    else
      flash.now[:alert] = "Gagal membuat booking."
      new_cs
      render :new_cs
    end
  end
  
  
    # form page
    def register_outside
      @branches = Branch.all
      if params[:branch_id].present? && params[:date].present?
        @selected_branch = Branch.find(params[:branch_id])
        @selected_date = Date.parse(params[:date])
        # Konversi nama hari ke Bahasa Indonesia
        day_name = convert_to_indonesian(@selected_date.strftime("%A"))
        
        # Ambil semua jadwal rutin untuk cabang dan hari tersebut
        schedules = @selected_branch.schedules.where(day: day_name)
        
        @available_slots = []
        # Durasi default booking adalah 30 menit
        booking_duration = 30.minutes
        schedules.each do |schedule|
          slot_time = schedule.start_time
          while slot_time + booking_duration <= schedule.end_time
            candidate_start = slot_time
            candidate_end   = slot_time + booking_duration
    
            # Cek apakah ada booking yang tumpang tindih dengan interval kandidat,
            # kecuali booking yang telah dibatalkan (status: canceled).
            conflict = Booking.where(schedule_id: schedule.id, booking_date: @selected_date)
                              .where.not(status: 'canceled')
                              .where("booking_time < ? AND booking_end_time > ?", candidate_end, candidate_start)
                              .exists?
            unless conflict
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
  
    # handle submit
    def create_register_outside
      bp = booking_params.except(:slot_combined)
      slot_combined = booking_params[:slot_combined]
    
      @booking = Booking.new(bp)
      # Misalnya, untuk CS, cabang diambil dari form (atau bisa juga otomatis)
      @booking.branch = Branch.find(booking_params[:branch_id]) if booking_params[:branch_id].present?
      @booking.created_by_id = 1
    
      if slot_combined.present?
        schedule_id, slot_str = slot_combined.split("|")
        schedule = Schedule.find(schedule_id)
        @booking.schedule = schedule
        @booking.booking_time = Time.zone.parse(slot_str)
        @booking.doctor = schedule.doctor
      else
        @booking.errors.add(:base, "Slot harus dipilih")
        render :register_outside and return
      end
    
      # Set default booking_end_time: jika tidak diisi, set menjadi booking_time + 30 menit
      if booking_params[:booking_end_time].blank?
        @booking.booking_end_time = @booking.booking_time + 30.minutes
      else
        @booking.booking_end_time = Time.zone.parse(booking_params[:booking_end_time])
      end
      
      @booking.status = :scheduled

      if @booking.save
        flash[:notice] = "Booking berhasil dibuat."
        redirect_to terima_kasih_pendaftaran_path(id: @booking.id)
      else
        flash.now[:alert] = "Gagal membuat booking."
        register_outside
        render :register_outside
      end
    end

    def thank_you_register
      @booking = Booking.find(params[:id])
      @branches = Branch.all
    end
    
    def schedules
      @selected_branch = Branch.find(params[:branch_id])
      @selected_date = Date.parse(params[:date])
      # Konversi nama hari ke Bahasa Indonesia
      day_name = convert_to_indonesian(@selected_date.strftime("%A"))
      
      # Ambil semua jadwal rutin untuk cabang dan hari tersebut
      schedules = @selected_branch.schedules.where(day: day_name)
      
      @available_slots = []
      # Durasi default booking adalah 30 menit
      booking_duration = 30.minutes
      schedules.each do |schedule|
        slot_time = schedule.start_time
        while slot_time + booking_duration <= schedule.end_time
          candidate_start = slot_time
          candidate_end   = slot_time + booking_duration
  
          # Cek apakah ada booking yang tumpang tindih dengan interval kandidat,
          # kecuali booking yang telah dibatalkan (status: canceled).
          conflict = Booking.where(schedule_id: schedule.id, booking_date: @selected_date)
                            .where.not(status: 'canceled')
                            .where("booking_time < ? AND booking_end_time > ?", candidate_end, candidate_start)
                            .exists?
          unless conflict
            @available_slots << { schedule: schedule, slot_time: slot_time }
          end
  
          slot_time += booking_duration
        end
      end
      render json: @available_slots.map { |s| { id: s.id, text: s.time_slot } }
    end

  private

  def booking_params
    params.require(:booking).permit(:service_id, :branch_id, :booking_date, :booking_time, :booking_end_time, :customer_name, :customer_phone, :slot_combined, :keterangan)
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
