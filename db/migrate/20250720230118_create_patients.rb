class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.string :full_name, null: false                     # Nama Lengkap
      t.string :identity_number                            # No. KTP / SIM / Passport
      t.string :gender, null: false                        # Jenis Kelamin (Laki-Laki / Perempuan)
      t.string :place_of_birth, null: false                # Tempat Lahir
      t.date :date_of_birth, null: false                   # Tanggal Lahir
      t.string :phone_number, null: false                  # No Telp Pribadi
      t.string :email, null: false                         # Email
      t.string :address, null: false                       # Alamat (sesuai identitas)
      t.string :subdistrict                                # Kelurahan
      t.string :district                                   # Kecamatan
      t.string :city                                       # Kabupaten/Kota
      t.string :province                                   # Provinsi
      t.string :blood_type, null: false                    # Golongan Darah
      t.string :emergency_contact_name, null: false        # Nama kerabat terdekat yang dapat dihubungi dalam keadaan darurat
      t.string :emergency_contact_phone, null: false       # No. Telp kerabat terdekat

      t.timestamps
    end
  end
end
