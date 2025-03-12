class AddDefaultStatusBooking < ActiveRecord::Migration[7.1]
  def change
    change_column_default :bookings, :status, "scheduled"
  end
end
