class InsertJadwalDokterJatibening < ActiveRecord::Migration[6.1]
  def up
    # Temukan atau buat cabang "JATIBENING"
    branch = Branch.find_or_create_by!(name: "JATIBENING")

    # Data jadwal dokter untuk cabang "JATIBENING"
    # Struktur: tiap elemen adalah hash dengan kunci :doctor dan :schedule
    # :schedule adalah hash dengan key nama hari (dalam bahasa Indonesia) dan value string range waktu "HH.MM - HH.MM"
    data = [
      {
        doctor: "drg. Dewi Ambunsari",
        schedule: {
          "Senin"  => "10.00 - 15.00",
          "Minggu" => "15.00 - 20.00"
        }
      },
      {
        doctor: "drg. Ning Ayu",
        schedule: {
          "Kamis" => "10.00 - 20.00",
          "Sabtu" => "15.00 - 20.00"
        }
      },
      {
        doctor: "drg. Nurina Habsah",
        schedule: {
          "Senin"  => "15.00 - 20.00",
          "Selasa" => "10.00 - 20.00"
        }
      },
      {
        doctor: "drg. Intan Neira",
        schedule: {
          "Rabu"   => "10.00 - 20.00",
          "Jum'at" => "10.00 - 15.00"
        }
      },
      {
        doctor: "drg. Wisnu D. Setiawan",
        schedule: {
          "Jum'at" => "15.00 - 20.00",
          "Sabtu"  => "10.00 - 15.00"
        }
      },
      {
        doctor: "drg. Yunita Mitasari",
        schedule: {
          "Minggu" => "10.00 - 15.00"
        }
      }
    ]

    data.each do |doctor_data|
      # Temukan atau buat dokter, terkait dengan cabang "JATIBENING"
      doctor = Doctor.find_or_create_by!(name: doctor_data[:doctor], branch: branch)
      
      doctor_data[:schedule].each do |day, time_range|
        next if time_range.nil? || time_range.strip.empty?

        # Ganti titik dengan titik dua untuk format "HH:MM"
        normalized_time_range = time_range.gsub('.', ':')
        times = normalized_time_range.split('-').map(&:strip)
        next unless times.size == 2

        start_str, end_str = times

        # Gunakan tanggal dummy karena yang penting adalah jam dan menit
        dummy_date = "2000-01-01"
        start_time = Time.zone.parse("#{dummy_date} #{start_str}")
        end_time   = Time.zone.parse("#{dummy_date} #{end_str}")

        Schedule.create!(
          branch: branch,
          doctor: doctor,
          day: day,
          start_time: start_time,
          end_time: end_time
        )
      end
    end

    puts "Data jadwal dokter untuk cabang 'JATIBENING' telah dimasukkan."
  end

  def down
    branch = Branch.find_by(name: "JATIBENING")
    return unless branch

    doctor_names = [
      "drg. Dewi Ambunsari",
      "drg. Ning Ayu",
      "drg. Nurina Habsah",
      "drg. Intan Neira",
      "drg. Wisnu D. Setiawan",
      "drg. Yunita Mitasari"
    ]
    doctors = Doctor.where(branch: branch, name: doctor_names)
    Schedule.where(doctor: doctors).destroy_all

    puts "Data jadwal dokter untuk cabang 'JATIBENING' telah dihapus."
  end
end
