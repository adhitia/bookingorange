class Staff::BookingsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_staff
    before_action :set_booking, only: [:show, :edit, :update, :cancel, :complete, :confirm]
    skip_forgery_protection only: [:available_slots]

    def index
        # Hanya tampilkan booking dari cabang staff
        @branches = [current_user.branch]
        @doctors  = Doctor.all
        @statuses = Booking.statuses.keys
        @bookings = Booking.where(branch_id: current_user.branch_id, status: :scheduled).includes(:doctor, :schedule)
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
        @booking.status = :confirmed
        if @booking.save
            flash[:notice] = "Booking berhasil dibuat."
            redirect_to timetable_staff_bookings_path
        else
            flash.now[:alert] = "Gagal membuat booking. " + @booking.errors.full_messages.join(", ")
            render :new_cs
        end
    end
    
    def today
        @bookings = Booking.where(branch_id: current_user.branch_id)
        .where(booking_date: Date.today)
        .order(:booking_time)
    end
    
    def all
        # Ambil semua booking untuk branch staff dengan booking_date >= hari ini
        @bookings = Booking.where(branch_id: current_user.branch_id)
                           .where("booking_date >= ?", Date.today)
                           .order(:booking_date, :booking_time)
        
        # Jika ada parameter :date, filter dengan tanggal spesifik
        if params[:date].present?
          @bookings = @bookings.where(booking_date: Date.parse(params[:date]))
        end
      
        # Filter berdasarkan doctor_id jika disediakan
        @bookings = @bookings.where(doctor_id: params[:doctor_id]) if params[:doctor_id].present?
      
        # Filter berdasarkan status jika disediakan
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
                    # unless Booking.exists?(schedule_id: schedule.id, booking_date: @selected_date, booking_time: slot_time)
                        @available_slots << { schedule: schedule, slot_time: slot_time }
                    # end
                    slot_time += booking_duration
                end
            end
        else
            @available_slots = []  # pastikan variabel ini selalu ada
        end
        @booking = Booking.new
    end
    
    # Action untuk mengonfirmasi booking
    def confirm
        if @booking.update(status: "confirmed")
            # Opsional: Kirim notifikasi WhatsApp
            # CekatApi.confirm_book(@booking)
            flash[:notice] = "Booking berhasil dikonfirmasi dan notifikasi WhatsApp telah dikirim."
            redirect_to staff_booking_path(@booking)
        else
            flash[:alert] = "Gagal mengonfirmasi booking."
            redirect_to staff_booking_path(@booking)
        end
    end
    
    
    def create_cs
        # Buat salinan parameter dan hapus slot_combined dari hash
        bp = booking_params.except(:slot_combined)
        slot_combined = booking_params[:slot_combined]
        
        @booking = Booking.new(bp)
        @booking.branch = current_user.branch
        @booking.created_by = current_user

        # Proses slot_combined untuk menentukan schedule, booking_time, dll.
        if slot_combined.present?
            schedule_id, slot_str = slot_combined.split("|")
            schedule = Schedule.find(schedule_id)
            @booking.schedule = schedule
            @booking.booking_time = Time.zone.parse(slot_str)
            @booking.doctor = schedule.doctor
        else
            @booking.errors.add(:base, "Slot harus dipilih")
            render :new and return
        end

        if booking_params[:booking_end_time].blank?
            @booking.booking_end_time = @booking.booking_time + 30.minutes
        else
            @booking.booking_end_time = Time.zone.parse(booking_params[:booking_end_time])
        end

        # Validasi end time jika diberikan
        if @booking.booking_time.present? && @booking.booking_end_time.present?
            end_time = @booking.booking_end_time
            if end_time <= @booking.booking_time
                @booking.errors.add(:booking_end_time, "harus lebih besar dari waktu mulai")
                render :new_cs and return
            else
                @booking.booking_end_time = end_time
            end
        else
            @booking.errors.add(:booking_end_time, "harus diisi")
            render :new_cs and return
        end
        @booking.status = :confirmed
        if @booking.save
            # CekatApi.confirm_book(@booking)
            flash[:notice] = "Booking berhasil dibuat."
            redirect_to staff_booking_path(@booking)
        else
            flash.now[:alert] = "Gagal membuat booking." + @booking.errors.full_messages.join(", ")
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
    
    # Action update (untuk edit/reschedule booking)
    def update
        bp = booking_params.except(:slot_combined)
        slot_combined = booking_params[:slot_combined]
        # Jika staff memilih slot baru, proses slot_combined untuk menentukan schedule, booking_time, dan doctor.
        if slot_combined.present?
          schedule_id, slot_str = slot_combined.split("|")
          @booking.schedule_id = schedule_id
          schedule = Schedule.find(schedule_id)
          bp[:booking_time] = Time.zone.parse(slot_str)
          bp[:doctor_id] = schedule.doctor_id
        end
        
        
        # Pastikan booking_end_time sudah diinput dan valid.
        if bp[:booking_end_time].present?
          new_end_time = bp[:booking_end_time]
          # Jika parameter adalah string, parsing; jika sudah Time, gunakan langsung.
          new_end_time = new_end_time.is_a?(String) ? Time.zone.parse(new_end_time) : new_end_time
        else
          @booking.errors.add(:booking_end_time, "tidak boleh kosong")
          load_available_slots(@booking.booking_date)
          render :edit and return
        end
      
        # Ambil waktu mulai dari parameter jika ada, atau gunakan booking yang sudah ada.
        new_start_time = if bp[:booking_time].present?
                           temp = bp[:booking_time]
                           temp = temp.is_a?(String) ? Time.zone.parse(temp) : temp
                           temp
                         else
                           @booking.booking_time
                         end
      
        if new_end_time <= new_start_time
          @booking.errors.add(:booking_end_time, "harus lebih besar dari waktu mulai")
          load_available_slots(@booking.booking_date)
          render :edit and return
        end
      
        bp[:booking_end_time] = new_end_time
        if @booking.update(bp)
          # Ubah status booking ke rescheduled jika ada perubahan jadwal.
          @booking.update(status: :confirmed)
        #   CekatApi.confirm_book(@booking)
          flash[:notice] = "Booking berhasil diupdate."
          redirect_to staff_booking_path(@booking)
        else
          flash.now[:alert] = "Gagal mengupdate booking."
          load_available_slots(@booking.booking_date)
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
        start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today
        # Ambil tanggal dari hari ini sampai 6 hari ke depan (total 7 hari)
        @dates = (start_date..(start_date + 6)).to_a
                
        # Definisikan time slot tiap 30 menit dari pukul 10:00 sampai 20:00
        start_time = Time.zone.parse("#{Date.today} 10:00")
        end_time   = Time.zone.parse("#{Date.today} 21:00")
        @time_slots = []
        while start_time < end_time
            @time_slots << start_time.strftime("%H:%M")
            start_time += 30.minutes
        end
        
        # Ambil semua booking untuk branch staff dalam rentang tanggal tersebut, kecuali yang dibatalkan
        @bookings = Booking.where(branch_id: current_user.branch_id, booking_date: start_date..(start_date + 6))
                           .where.not(status: 'canceled')
        
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
        params.require(:booking).permit(:booking_date, :booking_time, :customer_name, :customer_phone, :branch_id, :slot_combined, :booking_end_time, :keterangan, :tipe_booking, :schedule_id)
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