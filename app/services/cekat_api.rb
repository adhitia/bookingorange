require 'net/http'
require 'uri'
require 'json'

module CekatApi
  # Ubah API_URL jika perlu; contoh di bawah memakai URL HTTPS yang disediakan oleh cekat.ai.
  API_URL = ENV.fetch("CEKAT_API_URL", "https://api.cekat.ai")
  API_KEY = ENV.fetch("CEKAT_API_KEY")

  # Method untuk mengirim template WhatsApp
  def self.complete_bok(booking)
    uri = URI.parse("#{API_URL}/templates/send")
    
    headers = {
      "Content-Type" => "application/json",
      "api_key" => API_KEY
    }
    
    # Pastikan booking memiliki attribute yang diperlukan:
    # booking.customer_name, booking.booking_date, booking.booking_time, booking.doctor.name
    # Gunakan helper indonesian_date untuk format tanggal yang diinginkan.
    formatted_date = booking.booking_date.present? ? ApplicationController.helpers.indonesian_date(booking.booking_date) : ""
    formatted_time = booking.booking_time.present? ? booking.booking_time.strftime("%H:%M") : ""
    doctor_name    = booking.doctor.present? ? booking.doctor.name : ""
    

    # Contoh payload. Pastikan field inbox_id disesuaikan, misalnya bisa diambil dari booking atau dari konfigurasi.
    payload = {
      wa_template_id: "1171228227689800",  # Sesuaikan template ID yang telah di-APPROVED
      template_body_variables: [
        booking.customer_name,
        "customer satisfaction survey",
      ],
      inbox_id: "c76d94c4-4de3-4703-ab00-75ac56cee2be",  # Sesuaikan dengan ID inbox yang digunakan
      phone_number: sanitize_phone_number(booking.customer_phone),  # Pastikan sudah dalam format internasional, misal: "628123456789"
      phone_name: booking.customer_name,  # Nama penerima pesan
    }
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = payload.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    Rails.logger.info("Cekat API Response: #{result.inspect}")
    result
    rescue StandardError => e
      Rails.logger.error("Cekat API Error: #{e.message}")
      nil
  end

  # Method untuk mengirim template WhatsApp
  def self.confirm_book(booking)
    uri = URI.parse("#{API_URL}/templates/send")
    
    headers = {
      "Content-Type" => "application/json",
      "api_key" => API_KEY
    }
    
    # Pastikan booking memiliki attribute yang diperlukan:
    # booking.customer_name, booking.booking_date, booking.booking_time, booking.doctor.name
    # Gunakan helper indonesian_date untuk format tanggal yang diinginkan.
    formatted_date = booking.booking_date.present? ? ApplicationController.helpers.indonesian_date(booking.booking_date) : ""
    formatted_time = booking.booking_time.present? ? booking.booking_time.strftime("%H:%M") : ""
    doctor_name    = booking.doctor.present? ? booking.doctor.name : ""
    

    # Contoh payload. Pastikan field inbox_id disesuaikan, misalnya bisa diambil dari booking atau dari konfigurasi.
    payload = {
      wa_template_id: "1272709553806353",  # Sesuaikan template ID yang telah di-APPROVED
      template_body_variables: [
        booking.customer_name,
        "cabang #{booking.branch.name} pada #{formatted_date}",
        formatted_time
      ],
      inbox_id: "c76d94c4-4de3-4703-ab00-75ac56cee2be",  # Sesuaikan dengan ID inbox yang digunakan
      phone_number: sanitize_phone_number(booking.customer_phone),  # Pastikan sudah dalam format internasional, misal: "628123456789"
      phone_name: booking.customer_name,  # Nama penerima pesan
    }
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = payload.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    Rails.logger.info("Cekat API Response: #{result.inspect}")
    result
    rescue StandardError => e
      Rails.logger.error("Cekat API Error: #{e.message}")
      nil
  end

  # Fungsi sanitizer nomor telepon agar format internasional
  def self.sanitize_phone_number(phone)
    sanitized = phone.to_s.strip.gsub(/\s+/, '').gsub(/[-()]/, '')
    # Jika nomor telepon diawali dengan 0, ganti dengan 62 (kode negara Indonesia)
    if sanitized.start_with?("0")
      sanitized = "62" + sanitized[1..-1]
    end
    sanitized
  end

end
