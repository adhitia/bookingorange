class Booking < ApplicationRecord
  belongs_to :branch
  belongs_to :doctor
  belongs_to :schedule
  belongs_to :created_by, class_name: "User", optional: true
  enum status: { scheduled: 0, rescheduled: 1, confirmed: 2, complete: 3, canceled: 4 }
end
