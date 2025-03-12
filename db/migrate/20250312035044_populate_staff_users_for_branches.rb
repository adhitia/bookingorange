class PopulateStaffUsersForBranches < ActiveRecord::Migration[6.1]
  def up
    # Mapping nama cabang -> email user staff
    staff_emails = {
      "Daan Mogot"      => "orangedentalgpv@gmail.com",
      "Pasar Minggu"    => "orangedentalpsm@gmail.com",
      "Rawamangun"      => "orangedentalrwmid@gmail.com",
      "Kebon Jeruk"     => "orangedentalkbj@gmail.com",
      "Klender"         => "orangedentalkld@gmail.com",
      "Ciledug"         => "orangedentalcldg@gmail.com",
      "Sawangan"        => "orangedentalswg@gmail.com",
      "Harapan Indah"   => "orangedentalhpi@gmail.com",
      "Hankam"          => "orangedentalhankam@gmail.com",
      "Cawang"          => "orangedentalcwg@gmail.com",
      "Jatibening"      => "orangedentaljtb@gmail.com",
      "Bintaro"         => "orangedentalbntr@gmail.com",
      "Grogol"          => "orangedentalgrl@gmail.com",
      "Kebayoran"       => "orangedentalkby@gmail.com",
      "Ciracas"         => "orangedentalcrc@gmail.com",
      "Gunung Sahari"   => "orangedentalgns@gmail.com",
      "Pamulang"        => "orangedentalpmlg@gmail.com",
      "Tangerang"       => "orangedentaltgr@gmail.com",
      "Ciputat"         => "orangedentalcpt@gmail.com",
      "Cakung"          => "orangedentalckg@gmail.com"
    }

    staff_emails.each do |branch_name, email|
      branch = Branch.find_by(name: branch_name)
      unless branch
        puts "Cabang '#{branch_name}' tidak ditemukan. Lewati."
        next
      end

      # Jika model User menggunakan enum role: { admin: 0, customer_service: 1, staff_cabang: 2 }, misalnya
      # Pastikan role staff_cabang sudah ada di model user
      user = User.find_or_initialize_by(email: email)
      if user.new_record?
        user.name = "Staff #{branch_name}"
        user.branch_id = branch.id
        user.role = :staff_cabang
        # Set password default (bisa diubah user sendiri nanti)
        default_password = SecureRandom.hex(8)  # misal, 16 karakter hex
        user.password = "OrangeDentalStaff"
        user.password_confirmation = "OrangeDentalStaff"
        user.save!
        puts "Membuat user staff_cabang: #{email} (#{branch_name}) dengan password: OrangeDentalStaff"
      else
        # Jika user sudah ada, update branch dan role
        user.update!(branch_id: branch.id, role: :staff_cabang)
        puts "User #{email} sudah ada, diperbarui branch_id ke #{branch.id}."
      end
    end
  end

  def down
    # Jika di-rollback, hapus user yang dibuat
    staff_emails = [
      "orangedentalgpv@gmail.com",
      "orangedentalpsm@gmail.com",
      "orangedentalrwmid@gmail.com",
      "orangedentalkbj@gmail.com",
      "orangedentalkld@gmail.com",
      "orangedentalcldg@gmail.com",
      "orangedentalswg@gmail.com",
      "orangedentalhpi@gmail.com",
      "orangedentalhankam@gmail.com",
      "orangedentalcwg@gmail.com",
      "orangedentaljtb@gmail.com",
      "orangedentalbntr@gmail.com",
      "orangedentalgrl@gmail.com",
      "orangedentalkby@gmail.com",
      "orangedentalcrc@gmail.com",
      "orangedentalgns@gmail.com",
      "orangedentalpmlg@gmail.com",
      "orangedentaltgr@gmail.com",
      "orangedentalcpt@gmail.com",
      "orangedentalckg@gmail.com"
    ]
    User.where(email: staff_emails).destroy_all
  end
end
