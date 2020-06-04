# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_05_07_195454) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "imports", id: :serial, force: :cascade do |t|
    t.string "api_key"
    t.string "resource_type"
    t.text "mapping"
    t.integer "record_count"
    t.integer "success_count"
    t.integer "error_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.string "subdomain"
    t.text "data"
    t.text "full_errors"
    t.integer "rows_to_process"
    t.boolean "staging_run", default: false
    t.string "platform"
    t.integer "errors_to_allow"
    t.boolean "match_on_asset_serial", default: false, null: false
    t.index ["uuid"], name: "index_imports_on_uuid"
  end

end
