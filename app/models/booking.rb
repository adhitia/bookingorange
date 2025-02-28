class Booking < ApplicationRecord
  belongs_to :branch
  belongs_to :doctor
  belongs_to :schedule
  belongs_to :created_by, class_name: "User", optional: true
  enum status: { scheduled: 0, canceled: 1, rescheduled: 2, complete: 3 }
end
