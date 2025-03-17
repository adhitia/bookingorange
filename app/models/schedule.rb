class Schedule < ApplicationRecord
  belongs_to :branch
  belongs_to :doctor
  has_many :bookings
end
