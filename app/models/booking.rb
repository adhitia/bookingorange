require 'net/http'
require 'uri'
require 'json'

class Booking < ApplicationRecord
  belongs_to :branch
  belongs_to :doctor
  belongs_to :schedule
  belongs_to :created_by, class_name: "User", optional: true
  validate :no_duplicate_booking
  default_scope { where(deleted_at: nil) }

  enum status: { scheduled: 0, rescheduled: 1, confirmed: 2, complete: 3, canceled: 4 }
  enum tipe_booking: { new_patient: 0, existing_patient: 1, non_patient: 2}
  after_create :send_to_webhook

  def send_to_webhook
    return if customer_phone.blank?
    webhook_url = "https://primary-production-3167.up.railway.app/webhook/feb7180c-b267-4392-b1f9-55af98ad381b"

    uri = URI.parse(webhook_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Post.new(uri.path, {
      'Content-Type': 'application/json'
    })

    payload = {
      phone_number: normalize_phone_number(self.customer_phone)
    }

    request.body = payload.to_json

    response = http.request(request)

    Rails.logger.info("Webhook sent for booking ##{id} - Status: #{response.code}")
    response
  rescue => e
    Rails.logger.error("Failed to send webhook for booking ##{id}: #{e.message}")
    nil
  end

  private

  def normalize_phone_number(raw)
    return nil if raw.blank?

    num = raw.gsub(/\D/, "") # hapus karakter selain angka

    # +62812xxxx → 0812xxxx
    if num.start_with?("62")
      "0" + num[2..]
    elsif num.start_with?("8")
      "0" + num
    elsif num.start_with?("0")
      num
    else
      nil # ga valid
    end
  end

  def no_duplicate_booking
    # Cari booking lain yang memiliki field sama persis
    existing = Booking.where(
      branch_id: branch_id,
      booking_date: booking_date,
      booking_time: booking_time,
      customer_phone: customer_phone
    )
    # Kecualikan record ini jika sudah ada di DB
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:base, "Booking dengan data tersebut sudah ada.")
    end
  end

end
