namespace :booking do
    desc "Send reminder notifications for today's bookings"
    task send_reminders: :environment do
      # Ambil booking hari ini yang belum dibatalkan
      bookings = Booking.where(booking_date: Date.today).where(status: "confirmed")
      puts "Mengirim reminder untuk #{bookings.count} booking hari ini."
      
      bookings.each do |booking|
        result = CekatApi.send_template_reminder(booking)
        if result && result["success"]
          puts "Reminder berhasil dikirim untuk booking #{booking.id}."
        else
          puts "Gagal mengirim reminder untuk booking #{booking.id}: #{result.inspect}"
        end
      end
    end
  end