class AddBookingTimeToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :booking_time, :time
  end
end
