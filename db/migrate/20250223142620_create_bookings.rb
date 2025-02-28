class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :branch, null: false, foreign_key: true
      t.references :doctor, null: false, foreign_key: true
      t.references :schedule, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :customer_name
      t.string :customer_phone
      t.integer :status

      t.timestamps
    end
  end
end
