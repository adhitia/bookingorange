class AddReferralCodeToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :referral_code, :string
  end
end
