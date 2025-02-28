class InsertJadwalDokterGrogol < ActiveRecord::Migration[6.1]
  def up
    # Temukan atau buat cabang "Grogol"
    branch = Branch.find_or_create_by!(name: "Grogol")

    # Data jadwal dokter untuk cabang Grogol
    data = [
      {
        doctor: "drg. Birgitta Ajeng",
        schedule: {
          "Selasa" => "10.00 - 15.00 (1)",
          "Rabu"   => "10.00 - 20.00 (1)"
        }
      },
      {
        doctor: "drg. Jessica Kadarman",
        schedule: {
          "Selasa" => "10.00 - 20.00 (2)",
          "Kamis"  => "10.00 - 20.00 (2)",
          "Jum'at" => "10.00 - 15.00 (1)"
        }
      },
      {
        doctor: "drg. Muhammad Iqbal",
        schedule: {
          "Senin"   => "10.00 - 20.00 (2)",
          "Selasa"  => "15.00 - 20.00 (1)",
          "Rabu"    => "10.00 - 20.00 (2)",
          "Sabtu"   => "10.00 - 20.00 (2)",
          "Minggu"  => "10.00 - 20.00 (2)"
        }
      },
      {
        doctor: "drg. Paramitha Koriston",
        schedule: {
          "Kamis" => "10.00 - 15.00 (1)",
          "Sabtu" => "10.00 - 20.00 (1)"
        }
      },
      {
        doctor: "drg. Riyan Iman",
        schedule: {
          "Minggu" => "10.00 - 20.00 (1)"
        }
      },
      {
        doctor: "drg. Maria Savvyana, Sp. Perio",
        schedule: {
          "Kamis"  => "15.00 - 20.00 (1)",
          "Jum'at" => "15.00 - 20.00 (1)"
        }
      },
      {
        doctor: "drg. Veronica, Sp. Ort",
        schedule: {
          "Jum'at" => "10.00 - 20.00 (2)"
        }
      }
    ]

    # Proses setiap dokter dan jadwalnya
    data.each do |entry|
      # Temukan atau buat dokter terkait cabang "Grogol"
      doctor = Doctor.find_or_create_by!(name: entry[:doctor], branch: branch)

      entry[:schedule].each do |day, time_range|
        next if time_range.nil? || time_range.strip.empty?
        
        # Hilangkan informasi shift yang terdapat dalam tanda kurung, misalnya " (1)" atau " (2)"
        cleaned_time_range = time_range.sub(/ \(.+\)/, '')
        times = cleaned_time_range.split('-').map(&:strip)
        next unless times.size == 2
        
        start_str, end_str = times

        # Ubah format waktu: ganti titik dengan titik dua, misalnya "10.00" menjadi "10:00"
        start_str.gsub!('.', ':')
        end_str.gsub!('.', ':')

        # Gunakan tanggal dummy (misalnya "2000-01-01") untuk membuat objek Time
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

    puts "Data jadwal dokter untuk cabang 'Grogol' telah dimasukkan."
  end

  def down
    branch = Branch.find_by(name: "Grogol")
    return unless branch

    doctor_names = [
      "drg. Birgitta Ajeng",
      "drg. Jessica Kadarman",
      "drg. Muhammad Iqbal",
      "drg. Paramitha Koriston",
      "drg. Riyan Iman",
      "drg. Maria Savvyana, Sp. Perio",
      "drg. Veronica, Sp. Ort"
    ]
    doctors = Doctor.where(branch: branch, name: doctor_names)
    Schedule.where(doctor: doctors).destroy_all

    puts "Data jadwal dokter untuk cabang 'Grogol' telah dihapus."
  end
end
