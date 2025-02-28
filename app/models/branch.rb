class Branch < ApplicationRecord
    has_many :schedules
    has_many :doctors
    has_many :bookings
end
