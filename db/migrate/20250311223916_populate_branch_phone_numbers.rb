class PopulateBranchPhoneNumbers < ActiveRecord::Migration[6.1]
  def up
    # Fungsi helper untuk normalisasi nomor WA: menghapus spasi, tanda "-" dan tanda "+",
    # sehingga nomor dengan awalan "62" tidak memiliki karakter selain digit.
    normalize_phone = ->(number) do
      # Hapus semua karakter kecuali digit
      normalized = number.gsub(/\D/, '')
      # Jika nomor diawali dengan "62" atau "0", ubah sehingga formatnya "62..."
      if normalized.start_with?("0")
        normalized[1..-1].prepend("62")
      else
        normalized
      end
    end

    # Mapping nomor WA untuk masing-masing cabang
    branch_phones = {
      # Jakarta Barat
      "Kebon Jeruk"  => "+62 813-9840-5148",
      "Grogol"       => "+62 812-8815-9498",
      "Daan Mogot"   => "+62 812-1329-8091",
      # Jakarta Timur
      "Rawamangun"   => "+62 821-1435-0095",
      "Klender"      => "+62 821-2576-1253",
      "Ciracas"      => "+62 813-9840-5149",
      "Cawang"       => "+62 813-8031-6143",
      # Jakarta Selatan
      "Pasar Minggu" => "+62 813-9890-4415",
      "Kebayoran"    => "+62 821-2542-7856",
      "Kebagusan"    => "+62 813-8565-7730",
      "Bintaro"      => "+62 821-1242-5392",
      # Jakarta Pusat
      "Gunung Sahari"=> "+62 852-8012-6147",
      # Bekasi
      "Jatibening"   => "+62 813-8831-4957",
      "Harapan Indah"=> "+62 812-9500-9367",
      "Hankam"       => "+62 821-2317-9866",
      # Tangerang
      "Karawaci"     => "+62 852-1992-4592",
      "Pamulang"     => "+62 823-1007-8115",
      "Ciputat"      => "+62 823-2354-3991",
      "Ciledug"      => "+62 852-1986-1949",
      # Depok
      "Sawangan"     => "+62 852-1294-0804"
    }

    branch_phones.each do |branch_name, phone|
      branch = Branch.find_by(name: branch_name)
      if branch
        branch.update!(phone: normalize_phone.call(phone))
      else
        puts "Branch '#{branch_name}' tidak ditemukan, lewati."
      end
    end
  end

  def down
    # Hapus data phone dari branch yang ada di mapping
    branch_phones = [
      "Kebon Jeruk", "Grogol", "Daan Mogot",
      "Rawamangun", "Klender", "Ciracas", "Cawang",
      "Pasar Minggu", "Kebayoran", "Kebagusan", "Bintaro",
      "Gunung Sahari",
      "Jatibening", "Harapan Indah", "Hankam",
      "Karawaci", "Pamulang", "Ciputat", "Ciledug",
      "Sawangan"
    ]
    Branch.where(name: branch_phones).update_all(phone: nil)
  end
end