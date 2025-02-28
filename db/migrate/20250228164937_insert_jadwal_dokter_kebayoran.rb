class InsertJadwalDokterKebayoran < ActiveRecord::Migration[6.1]
  def up
    # Temukan atau buat cabang "Kebayoran"
    branch = Branch.find_or_create_by!(name: "Kebayoran")

    # Data jadwal dokter untuk cabang Kebayoran
    # Struktur: tiap elemen adalah hash dengan:
    #   :doctor => nama dokter
    #   :schedule => hash jadwal, key: hari (dalam bahasa Indonesia),
    #                value: string range waktu dengan keterangan shift
    data = [
      {
        doctor: "drg. Agitha Azahara",
        schedule: {
          "Senin"   => "10.00-15.00 (1)",
          "Jum'at"  => "10.00 - 15.00  (1)",
          "Minggu"  => "10.00 - 15.00  (1)"
        }
      },
      {
        doctor: "drg. Arrysa Nadiana",
        schedule: {
          "Kamis"  => "10.00 - 15.00  (2)",
          "Jum'at" => "10.00 - 15.00  (2)",
          "Sabtu"  => "10.00 - 20.00  (2)"
        }
      },
      {
        doctor: "drg. Citra Ayu",
        schedule: {
          "Selasa" => "15.00 - 20.00  (1)",
          "Rabu"   => "10.00 - 15.00  (1)",
          "Jum'at" => "10.00 - 15.00  (1)"
        }
      },
      {
        doctor: "drg. Fanny Nuradiyah",
        schedule: {
          "Selasa" => "10.00-15.00  (1)",
          "Rabu"   => "15.00 - 20.00  (2)",
          "Kamis"  => "10.00 - 20.00  (1)"
        }
      },
      {
        doctor: "drg. Riyan Imam",
        schedule: {
          "Senin"  => "15.00 - 20.00  (1)",
          "Rabu"   => "15.00 - 20.00  (1)",
          "Kamis"  => "15.00 - 20.00  (2)",
          "Jum'at" => "15.00 - 20.00  (2)",
          "Sabtu"  => "15.00 - 20.00  (1)"
        }
      },
      {
        doctor: "drg. Varen Nadiya",
        schedule: {
          "Selasa" => "10.00 - 20.00  (2)",
          "Rabu"   => "10.00 - 15.00  (2)",
          "Jum'at" => "10.00 - 20.00  (2)"
        }
      },
      {
        doctor: "drg. Zalfa Karimah",
        schedule: {
          "Kamis"  => "15.00 - 20.00  (1)",
          "Sabtu"  => "15.00 - 20.00  (1)",
          "Minggu" => "15.00 - 20.00  (1)"
        }
      }
    ]

    data.each do |entry|
      # Temukan atau buat dokter terkait cabang "Kebayoran"
      doctor = Doctor.find_or_create_by!(name: entry[:doctor], branch: branch)
      
      entry[:schedule].each do |day, time_range|
        next if time_range.nil? || time_range.strip.empty?

        # Hilangkan bagian dalam tanda kurung, misalnya " (1)" atau " (2)"
        cleaned_time_range = time_range.sub(/ \(.+\)/, '')
        times = cleaned_time_range.split('-').map(&:strip)
        next unless times.size == 2

        start_str, end_str = times

        # Ubah format waktu: ganti titik dengan titik dua (contoh: "10.00" menjadi "10:00")
        start_str.gsub!('.', ':')
        end_str.gsub!('.', ':')

        # Gunakan tanggal dummy (misalnya "2000-01-01") untuk memparsing waktu
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

    puts "Data jadwal dokter untuk cabang 'Kebayoran' telah dimasukkan."
  end

  def down
    branch = Branch.find_by(name: "Kebayoran")
    return unless branch

    doctor_names = [
      "drg. Agitha Azahara",
      "drg. Arrysa Nadiana",
      "drg. Citra Ayu",
      "drg. Fanny Nuradiyah",
      "drg. Riyan Imam",
      "drg. Varen Nadiya",
      "drg. Zalfa Karimah"
    ]
    doctors = Doctor.where(branch: branch, name: doctor_names)
    Schedule.where(doctor: doctors).destroy_all

    puts "Data jadwal dokter untuk cabang 'Kebayoran' telah dihapus."
  end
end
