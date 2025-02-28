class InsertCabang < ActiveRecord::Migration[7.1]
  def up
    branch_names = [
      "Cawang",
      "Jatibening",
      "Bintaro",
      "Grogol",
      "Kebayoran",
      "Ciracas",
      "Gunung Sahari",
      "Pamulang",
      "Tangerang",
      "Ciputat",
      "Sawangan",
      "Ciledug",
      "Klender",
      "Harapan Indah",
      "Pasar Minggu",
      "Kebon Jeruk",
      "Hankam",
      "Kebagusan",
      "Daan Mogot",
      "Rawamangun"
    ]

    branch_names.each do |name|
      # Hanya membuat cabang jika belum ada
      unless Branch.exists?(name: name)
        Branch.create!(name: name)
      end
    end
  end

  def down
    branch_names = [
      "Cawang",
      "Jatibening",
      "Bintaro",
      "Grogol",
      "Kebayoran",
      "Ciracas",
      "Gunung Sahari",
      "Pamulang",
      "Tangerang",
      "Ciputat",
      "Sawangan",
      "Ciledug",
      "Klender",
      "Harapan Indah",
      "Pasar Minggu",
      "Kebon Jeruk",
      "Hankam",
      "Kebagusan",
      "Daan Mogot",
      "Rawamangun"
    ]
    
    branch_names.each do |name|
      branch = Branch.find_by(name: name)
      branch.destroy if branch.present?
    end
  end
end
