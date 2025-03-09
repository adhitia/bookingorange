class AddKeteranganToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :keterangan, :string
  end
end
