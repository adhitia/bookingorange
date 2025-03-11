class AddPhoneToBranches < ActiveRecord::Migration[7.1]
  def change
    add_column :branches, :phone, :string
  end
end
