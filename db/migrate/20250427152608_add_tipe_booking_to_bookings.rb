class AddTipeBookingToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :tipe_booking, :integer, default: 0
  end
end
