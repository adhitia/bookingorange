module Api
    module V1
      class SchedulesController < ApplicationController
        def check
          dday = params[:date].to_date
          branches = Branch.where(name: params[:lokasi])
  
          data = branches.map do |branch|
            {
              branch_name: branch.name,
              timeslots: build_timeslots(branch, dday)
            }
          end
          render json: { data: data }, status: :ok
        end
  
        private
  
        def build_timeslots(branch, date)
          booking_duration = 30.minutes
          slots = []


          day_name = convert_to_indonesian(date.strftime("%A"))
          schedules = branch.schedules.where(day: day_name)
          schedules.each do |schedule|
            slot_time = schedule.start_time

            while (slot_time + booking_duration) <= schedule.end_time
              candidate_start = slot_time
              candidate_end   = slot_time + booking_duration
              
              conflict = Booking.where(schedule_id: schedule.id, booking_date: date)
                                .where.not(status: 'canceled')
                                .where("booking_time < ? AND booking_end_time > ?", candidate_end, candidate_start)
                                .exists?

              unless conflict
                slots << {
                  date: date,
                  start_time: slot_time.strftime("%H:%M"),
                  end_time: (slot_time + booking_duration).strftime("%H:%M"),
                  available: true
                }
              end
  
              slot_time += booking_duration
            end
          end

          return slots
        end

        def convert_to_indonesian(day_name)
          mapping = {
          "Monday"    => "Senin",
          "Tuesday"   => "Selasa",
          "Wednesday" => "Rabu",
          "Thursday"  => "Kamis",
          "Friday"    => "Jumat",
          "Saturday"  => "Sabtu",
          "Sunday"    => "Minggu"
          }
          mapping[day_name] || day_name
        end

      end
    end
  end