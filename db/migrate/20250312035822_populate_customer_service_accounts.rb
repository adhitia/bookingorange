class PopulateCustomerServiceAccounts < ActiveRecord::Migration[6.1]
  def up
    # Pastikan role customer_service sudah ada di model (enum)
    # Kita akan membuat 10 akun CS
    (1..10).each do |i|
      email = "CS#{i}@orangedentalhouse.com"
      user = User.find_or_initialize_by(email: email)
      if user.new_record?
        user.name = "Customer Service #{i}"
        user.role = :customer_service
        user.password = "OrangeDentalCS"
        user.password_confirmation = "OrangeDentalCS"
        user.save!
        puts "Membuat akun CS: #{email}"
      else
        # Jika user sudah ada, pastikan role dan password sesuai
        user.update!(role: :customer_service,
                     password: "OrangeDentalCS",
                     password_confirmation: "OrangeDentalCS")
        puts "Memperbarui akun CS: #{email}"
      end
    end
  end

  def down
    # Jika di-rollback, hapus 10 akun ini
    (1..10).each do |i|
      email = "CS#{i}@orangedentalhouse.com"
      user = User.find_by(email: email)
      user&.destroy
    end
  end
end
