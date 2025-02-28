class Staff::BookingsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_staff
    before_action :set_booking, only: [:show, :edit, :update, :cancel, :complete]
    
    def index
        # Hanya tampilkan booking dari cabang staff
        @branches = [current_user.branch]
        @doctors  = Doctor.all
        @statuses = Booking.statuses.keys
        @bookings = Booking.where(branch_id: current_user.branch_id).includes(:doctor, :schedule)
    end
    
    def new
        @booking = Booking.new
        @booking.branch = current_user.branch
        @booking.created_by = current_user
        @booking.booking_date = params[:booking_date] ? Date.parse(params[:booking_date]) : Date.today
        if params[:booking_time].present?
          # Misalnya, kita menyimpan booking_time sebagai waktu (dalam zona waktu aplikasi)
          @booking.booking_time = Time.zone.parse("#{Date.today} #{params[:booking_time]}")
          # Perlu disesuaikan agar tanggalnya sesuai dengan booking_date yang diinginkan
          @booking.booking_time = Time.zone.parse("#{@booking.booking_date} #{params[:booking_time]}")
        end
      end
      
    def show
    end
    

    def create
        @booking = Booking.new(booking_params)
        @booking.branch = current_user.branch
        @booking.created_by = current_user
      
        # Coba temukan schedule yang sesuai berdasarkan booking_date dan booking_time
        day_name = convert_to_indonesian(@booking.booking_date.strftime("%A"))
        # Cari schedule di cabang staff dengan hari yang sesuai
        matching_schedule = current_user.branch.schedules.find do |s|
          # Perbandingan berdasarkan string "HH:MM"
          slot = @booking.booking_time.strftime("%H:%M")
          start_slot = s.start_time.strftime("%H:%M")
          end_slot = s.end_time.strftime("%H:%M")
          slot >= start_slot && slot < end_slot
        end
      
        if matching_schedule
          @booking.schedule = matching_schedule
          @booking.doctor = matching_schedule.doctor
        else
          @booking.errors.add(:base, "Tidak ada jadwal yang sesuai untuk waktu yang dipilih")
          flash.now[:alert] = "Gagal membuat booking. " + @booking.errors.full_messages.join(", ")
          render :new and return
        end
      
        if @booking.save
          flash[:notice] = "Booking berhasil dibuat."
          redirect_to timetable_staff_bookings_path
        else
          flash.now[:alert] = "Gagal membuat booking."
          render :new
        end
      end

    def today
        @bookings = Booking.where(branch_id: current_user.branch_id)
        .where(booking_date: Date.today)
        .order(:booking_time)
    end
    
    # Semua booking dengan filter (filter: tanggal, dokter, status)
    def all
        @bookings = Booking.where(branch_id: current_user.branch_id).order(:booking_date, :booking_time)
        
        # Filter berdasarkan tanggal jika disediakan
        @bookings = @bookings.where(booking_date: Date.parse(params[:date])) if params[:date].present?
        
        # Filter berdasarkan dokter (doctor_id)
        @bookings = @bookings.where(doctor_id: params[:doctor_id]) if params[:doctor_id].present?
        
        # Filter berdasarkan status (misal: scheduled, canceled, rescheduled, complete)
        @bookings = @bookings.where(status: params[:status]) if params[:status].present?
        
        # Untuk dropdown filter dokter
        @doctors = Doctor.where(branch_id: current_user.branch_id)
    end
    
    # Form booking untuk Customer Service
    def new_cs
        @branches = @selected_branch = current_user.branch
        if params[:date].present?
            @selected_date = Date.parse(params[:date])
            day_name = convert_to_indonesian(@selected_date.strftime("%A"))
            # Ambil jadwal untuk cabang staff yang sesuai dengan hari tersebut
            schedules = @branches = @selected_branch.schedules.where(day: day_name)
            
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
            @available_slots = []  # pastikan variabel ini selalu ada
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
            @booking.doctor = schedule.doctor
        end
        @booking.branch = current_user.branch
        @booking.created_by = current_user
        if @booking.save
            flash[:notice] = "Booking berhasil dibuat."
            redirect_to staff_booking_path(@booking)
        else
            flash.now[:alert] = "Gagal membuat booking."
            new_cs  # reload variabel filter
            render :new_cs
        end
    end
    
    
    
    def edit
        # Gunakan booking_date dari booking atau default ke hari ini
        @booking_date = @booking.booking_date || Date.today
        # Konversi tanggal ke nama hari (dalam Bahasa Indonesia)
        day_name = convert_to_indonesian(@booking_date.strftime("%A"))
        # Ambil semua jadwal rutin untuk cabang staff yang sesuai dengan hari tersebut
        schedules = current_user.branch.schedules.where(day: day_name)
        booking_duration = 30.minute
        @available_slots = []
        
        schedules.each do |schedule|
            slot_time = schedule.start_time
            while slot_time + booking_duration <= schedule.end_time
                # Cari booking untuk schedule ini di tanggal dan waktu slot tersebut
                existing_booking = Booking.find_by(schedule_id: schedule.id, booking_date: @booking_date, booking_time: slot_time)
                # Jika slot tidak terpakai atau slot milik booking yang sedang diedit, masukkan ke available slots
                if existing_booking.nil? || existing_booking.id == @booking.id
                    @available_slots << { schedule: schedule, slot_time: slot_time }
                end
                slot_time += booking_duration
            end
        end
    end
    
    def update
        bp = booking_params.dup
        slot_combined = bp.delete(:slot_combined)
        if slot_combined.present?
            schedule_id, slot_str = slot_combined.split("|")
            schedule = Schedule.find(schedule_id)
            bp[:schedule_id] = schedule_id
            bp[:booking_time] = Time.parse(slot_str)
            bp[:doctor_id] = schedule.doctor_id
        end
        
        if @booking.update(bp)
            # Jika update berhasil, ubah status menjadi rescheduled
            @booking.update(status: :rescheduled)
            flash[:notice] = "Booking berhasil direschedule."
            redirect_to staff_booking_path(@booking)
        else
            flash.now[:alert] = "Gagal melakukan reschedule booking."
            render :edit
        end
    end
    
    def cancel
        @booking.status = :canceled
        if @booking.save
            flash[:notice] = "Booking berhasil dibatalkan."
            redirect_to all_staff_bookings_path
        else
            flash[:alert] = "Gagal membatalkan booking."
            redirect_to staff_booking_path(@booking)
        end
    end
    
    def complete
        @booking.status = :complete
        if @booking.save
            flash[:notice] = "Booking telah diselesaikan."
            redirect_to all_staff_bookings_path
        else
            flash[:alert] = "Gagal mengubah status booking."
            redirect_to staff_booking_path(@booking)
        end
    end
    
    # Aksi untuk Ajax: hitung slot available berdasarkan tanggal
    def available_slots
        booking_date = Date.parse(params[:booking_date])
        day_name = convert_to_indonesian(booking_date.strftime("%A"))
        schedules = current_user.branch.schedules.where(day: day_name)
        booking_duration = 30.minute
        available_slots = []
        
        schedules.each do |schedule|
            slot_time = schedule.start_time
            while slot_time + booking_duration <= schedule.end_time
                # Cek apakah slot ini sudah ter-booking untuk tanggal tersebut
                unless Booking.exists?(schedule_id: schedule.id, booking_date: booking_date, booking_time: slot_time)
                    available_slots << { schedule: schedule, slot_time: slot_time }
                end
                slot_time += booking_duration
            end
        end
        
        @available_slots = available_slots
        respond_to do |format|
            format.js   # akan merender file available_slots.js.erb
        end
    end

    def timetable
        # Ambil tanggal dari hari ini sampai 6 hari ke depan (total 7 hari)
        @dates = (Date.today..(Date.today + 6)).to_a
    
        # Definisikan time slot tiap 30 menit dari pukul 10:00 sampai 20:00
        start_time = Time.zone.parse("#{Date.today} 10:00")
        end_time   = Time.zone.parse("#{Date.today} 20:00")
        @time_slots = []
        while start_time < end_time
          @time_slots << start_time.strftime("%H:%M")
          start_time += 30.minutes
        end
    
        # Ambil semua booking untuk branch staff dalam rentang tanggal tersebut
        @bookings = Booking.where(branch_id: current_user.branch_id, booking_date: Date.today..(Date.today + 6))
        
        # Buat lookup hash dengan key: [booking_date, booking_time_str]
        @booking_lookup = {}
        @bookings.each do |booking|
          key = [booking.booking_date, booking.booking_time.strftime("%H:%M")]
          @booking_lookup[key] = booking
        end
      end   
    
    private
    
    def set_booking
        @booking = Booking.find(params[:id])
        # Pastikan booking tersebut berasal dari cabang staff
        unless @booking.branch_id == current_user.branch_id
            flash[:alert] = "Anda tidak memiliki akses ke booking ini."
            redirect_to all_staff_bookings_path
        end
    end
    
    def booking_params
        params.require(:booking).permit(:booking_date, :booking_time, :customer_name, :customer_phone)
    end
    
    def authorize_staff
        unless current_user.staff_cabang?
            flash[:alert] = "Akses hanya untuk staff cabang."
            redirect_to root_path
        end
    end
    
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

# Helper untuk menghitung available slots berdasarkan booking_date
def load_available_slots(date)
    day_name = convert_to_indonesian(date.strftime("%A"))
    schedules = current_user.branch.schedules.where(day: day_name)
    booking_duration = 30.minute
    available_slots = []
    schedules.each do |schedule|
        slot_time = schedule.start_time
        while slot_time + booking_duration <= schedule.end_time
            # Jika slot sudah dipakai oleh booking lain, lewati; jika slot milik booking yang diedit, izinkan
            existing = Booking.find_by(schedule_id: schedule.id, booking_date: date, booking_time: slot_time)
            if existing.nil? || existing.id == @booking.id
                available_slots << { schedule: schedule, slot_time: slot_time }
            end
            slot_time += booking_duration
        end
    end
    @available_slots = available_slots
end

end