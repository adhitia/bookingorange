class Doctor < ApplicationRecord
  belongs_to :branch
  has_many :schedules, dependent: :destroy
  validates :name, presence: true
  validates :branch, presence: true
end
