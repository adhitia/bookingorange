class InsertJadwalDokterCawang < ActiveRecord::Migration[6.1]
  def up
    # Temukan atau buat cabang "CAWANG"
    branch = Branch.find_or_create_by!(name: "CAWANG")

    # Data jadwal dokter untuk cabang "CAWANG"
    # Struktur data: tiap elemen merupakan hash dengan:
    #  - :doctor => nama dokter (string)
    #  - :schedule => hash jadwal, key: hari (string), value: string time range "HH.MM - HH.MM"
    data = [
      {
        doctor: "drg. Anesha Destilyana",
        schedule: {
          "Sabtu" => "10.00 - 20.00"
        }
      },
      {
        doctor: "drg. Ali Akbar",
        schedule: {
          "Senin"   => "15.00 - 20.00",
          "Minggu"  => "15.00 - 20.00"
        }
      },
      {
        doctor: "drg. Karina Sabriati",
        schedule: {
          "Rabu" => "10.00 - 15.00"
        }
      },
      {
        doctor: "drg. Khairunnisa",
        schedule: {
          "Senin" => "10.00 - 15.00",
          "Rabu"  => "10.00 - 15.00"
        }
      },
      {
        doctor: "drg. Ratih Dwi Lestari",
        schedule: {
          "Rabu"   => "15.00 - 20.00",
          "Kamis"  => "15.00 - 20.00",
          "Jum'at" => "10.00 - 15.00"
        }
      },
      {
        doctor: "drg. Rinezia",
        schedule: {
          "Rabu"  => "15.00 - 20.00",
          "Kamis" => "10.00 - 15.00"
        }
      },
      {
        doctor: "drg. Elizabeth, Sp. KG",
        schedule: {
          "Jum'at" => "15.00 - 20.00",
          "Minggu" => "10.00 - 15.00"
        }
      }
    ]

    # Iterasi setiap dokter dan buat record schedule
    data.each do |doctor_data|
      # Temukan atau buat dokter, terkait dengan cabang "CAWANG"
      doctor = Doctor.find_or_create_by!(name: doctor_data[:doctor], branch: branch)
      doctor_data[:schedule].each do |day, time_range|
        # Lewati jika nilai time_range kosong
        next if time_range.nil? || time_range.strip.empty?

        # Ganti titik dengan titik dua agar format waktu menjadi "HH:MM"
        time_range = time_range.gsub('.', ':')
        times = time_range.split('-').map(&:strip)
        next if times.size != 2

        start_str, end_str = times

        # Karena hanya informasi waktu, gunakan tanggal dummy (misalnya, "2000-01-01")
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

    puts "Data jadwal dokter untuk cabang 'CAWANG' telah dimasukkan."
  end

  def down
    branch = Branch.find_by(name: "CAWANG")
    return unless branch

    # Hapus schedule untuk dokter-dokter yang ada di data
    doctor_names = [
      "drg. Anesha Destilyana",
      "drg. Ali Akbar",
      "drg. Karina Sabriati",
      "drg. Khairunnisa",
      "drg. Ratih Dwi Lestari",
      "drg. Rinezia",
      "drg. Elizabeth, Sp. KG"
    ]
    doctors = Doctor.where(branch: branch, name: doctor_names)
    Schedule.where(doctor: doctors).destroy_all

    puts "Data jadwal dokter untuk cabang 'CAWANG' telah dihapus."
  end
end
