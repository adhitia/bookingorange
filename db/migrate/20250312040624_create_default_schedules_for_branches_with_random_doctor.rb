class CreateDefaultSchedulesForBranchesWithRandomDoctor < ActiveRecord::Migration[6.1]
  def up
    days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
    dummy_date = "2000-01-01"
    default_start = Time.zone.parse("#{dummy_date} 10:00")
    default_end   = Time.zone.parse("#{dummy_date} 21:00")

    Branch.where.not(name: "Pamulang").find_each do |branch|
      doctors = branch.doctors.to_a
      # Jika belum ada dokter, buat satu dokter default
      if doctors.empty?
        default_doctor = Doctor.create!(name: "Dr. Default #{branch.name}", branch: branch)
        doctors << default_doctor
      end

      # Batasi hanya 2 dokter per cabang untuk mendapatkan schedule default
      limited_doctors = doctors.first(1)

      limited_doctors.each do |doctor|
        days.each do |day|
          Schedule.find_or_create_by!(
            branch: branch,
            doctor: doctor,
            day: day,
            start_time: default_start,
            end_time: default_end
          )
          puts "Schedule #{day} untuk dokter #{doctor.name} di cabang #{branch.name} telah dibuat."
        end
      end
    end
  end

  def down
    days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
    dummy_date = "2000-01-01"
    default_start = Time.zone.parse("#{dummy_date} 10:00")
    default_end   = Time.zone.parse("#{dummy_date} 21:00")

    Branch.where.not(name: "Pamulang").find_each do |branch|
      branch.doctors.find_each do |doctor|
        days.each do |day|
          schedule = Schedule.find_by(
            branch: branch,
            doctor: doctor,
            day: day,
            start_time: default_start,
            end_time: default_end
          )
          schedule.destroy if schedule
        end
      end
    end
  end
end
