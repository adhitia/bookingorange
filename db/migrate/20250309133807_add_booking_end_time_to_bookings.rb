class AddBookingEndTimeToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :booking_end_time, :time
  end
end
