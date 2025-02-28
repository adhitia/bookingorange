class AddDayToSchedules < ActiveRecord::Migration[7.1]
  def change
    add_column :schedules, :day, :string
  end
end
