class AddServiceToBookings < ActiveRecord::Migration[6.1]
  def change
    add_reference :bookings, :service, foreign_key: true, null: true
  end
end