# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_03_11_223916) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "branch_id", null: false
    t.bigint "doctor_id", null: false
    t.bigint "schedule_id", null: false
    t.bigint "created_by_id", null: false
    t.string "customer_name"
    t.string "customer_phone"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "booking_date"
    t.time "booking_time"
    t.time "booking_end_time"
    t.string "keterangan"
    t.index ["branch_id"], name: "index_bookings_on_branch_id"
    t.index ["created_by_id"], name: "index_bookings_on_created_by_id"
    t.index ["doctor_id"], name: "index_bookings_on_doctor_id"
    t.index ["schedule_id"], name: "index_bookings_on_schedule_id"
  end

  create_table "branches", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
  end

  create_table "doctors", force: :cascade do |t|
    t.string "name"
    t.bigint "branch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_doctors_on_branch_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "branch_id", null: false
    t.bigint "doctor_id", null: false
    t.date "date"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "day"
    t.index ["branch_id"], name: "index_schedules_on_branch_id"
    t.index ["doctor_id"], name: "index_schedules_on_doctor_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.integer "branch_id"
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bookings", "branches"
  add_foreign_key "bookings", "doctors"
  add_foreign_key "bookings", "schedules"
  add_foreign_key "bookings", "users", column: "created_by_id"
  add_foreign_key "doctors", "branches"
  add_foreign_key "schedules", "branches"
  add_foreign_key "schedules", "doctors"
end
