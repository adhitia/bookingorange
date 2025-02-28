class InsertJadwalDokterBintaro < ActiveRecord::Migration[6.1]
  def up
    # Temukan atau buat cabang "BINTARO"
    branch = Branch.find_or_create_by!(name: "BINTARO")

    # Data jadwal dokter untuk cabang BINTARO
    # Struktur: tiap elemen adalah hash dengan:
    #   :doctor => nama dokter
    #   :schedule => hash jadwal, key: hari (dalam bahasa Indonesia),
    #                value: string range waktu (dengan info shift, misalnya "15.00 - 20.00 (2)")
    data = [
      {
        doctor: "drg. Adisti Calliandra",
        schedule: {
          "Selasa"  => "15.00 - 20.00 (2)",
          "Jum'at"  => "10.00 - 15.00 (2)",
          "Minggu"  => "15.00 - 20.00 (2)"
        }
      },
      {
        doctor: "drg. Agitha Azahara",
        schedule: {
          "Rabu"   => "10.00 - 15.00 (1)",
          "Kamis"  => "15.00 - 20.00 (2)",
          "Sabtu"  => "10.00 - 15.00 (2)"
        }
      },
      {
        doctor: "drg. Donny Adhimukti",
        schedule: {
          "Rabu" => "10.00 - 20.00 (2)"
        }
      },
      {
        doctor: "drg. Kharisya Handayani",
        schedule: {
          "Senin"  => "10.00 - 15.00 (1)",
          "Selasa" => "15.00 - 20.00 (1)",
          "Kamis"  => "10.00 - 15.00 (2)",
          "Sabtu"  => "15.00 - 20.00 (2)"
        }
      },
      {
        doctor: "drg. Linda Antika",
        schedule: {
          "Selasa"  => "10.00 - 15.00 (1)",
          "Jum'at"  => "15.00 - 20.00 (2)",
          "Minggu"  => "10.00 - 15.00 (2)"
        }
      },
      {
        doctor: "drg. Merriana Nurbaya",
        schedule: {
          "Senin" => "15.00 - 20.00 (1)",
          "Sabtu" => "10.00 - 15.00 (1)"
        }
      },
      {
        doctor: "drg. Nabila Khalisa",
        schedule: {
          "Selasa"  => "10.00 - 15.00 (2)",
          "Rabu"    => "15.00 - 20.00 (1)",
          "Jum'at"  => "10.00 - 20.00 (1)"
        }
      },
      {
        doctor: "drg. Steffanie Juliani",
        schedule: {
          "Kamis" => "10.00 - 15.00 (1)",
          "Sabtu" => "15.00 - 20.00 (1)"
        }
      },
      {
        doctor: "drg. Stiefani Vega",
        schedule: {
          "Kamis"  => "15.00 - 20.00 (1)",
          "Minggu" => "10.00 - 20.00 (1)"
        }
      }
    ]

    # Proses setiap data dokter
    data.each do |entry|
      # Temukan atau buat dokter, terkait dengan cabang BINTARO
      doctor = Doctor.find_or_create_by!(name: entry[:doctor], branch: branch)

      # Proses setiap jadwal di entry
      entry[:schedule].each do |day, time_range|
        next if time_range.nil? || time_range.strip.empty?
        
        # Hilangkan bagian dalam tanda kurung, misalnya " (2)" atau " (1)"
        cleaned_time_range = time_range.sub(/ \(.+\)/, '')
        times = cleaned_time_range.split('-').map(&:strip)
        next unless times.size == 2
        
        start_str, end_str = times

        # Ubah titik menjadi titik dua, jika diperlukan (misal: "10.00" menjadi "10:00")
        start_str.gsub!('.', ':')
        end_str.gsub!('.', ':')

        # Gunakan tanggal dummy (misalnya, "2000-01-01") untuk memparsing waktu
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

    puts "Data jadwal dokter untuk cabang 'BINTARO' telah dimasukkan."
  end

  def down
    branch = Branch.find_by(name: "BINTARO")
    return unless branch

    doctor_names = [
      "drg. Adisti Calliandra",
      "drg. Agitha Azahara",
      "drg. Donny Adhimukti",
      "drg. Kharisya Handayani",
      "drg. Linda Antika",
      "drg. Merriana Nurbaya",
      "drg. Nabila Khalisa",
      "drg. Steffanie Juliani",
      "drg. Stiefani Vega"
    ]
    doctors = Doctor.where(branch: branch, name: doctor_names)
    Schedule.where(doctor: doctors).destroy_all

    puts "Data jadwal dokter untuk cabang 'BINTARO' telah dihapus."
  end
end
