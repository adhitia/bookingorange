# app/helpers/patients_helper.rb
require 'rqrcode'

module PatientHelper
  def render_qr_code(patient)
    # Membuat URL lengkap ke halaman detail pasien
    # Gunakan `_url` agar mendapatkan domain lengkap, penting untuk QR code
    url = new_patient_url(booking: patient)

    # Membuat objek QR code dari URL
    qrcode = RQRCode::QRCode.new(url)

    # Merender QR code sebagai SVG (Scalable Vector Graphics)
    # SVG lebih baik dari gambar biasa karena tidak pecah saat diperbesar
    svg = qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4, # Ukuran modul (kotak kecil) QR code
      standalone: true
    )

    # Mengembalikan string SVG yang aman untuk ditampilkan di HTML
    svg.html_safe
  end
end