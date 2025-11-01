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

ActiveRecord::Schema[8.0].define(version: 2025_10_31_090349) do
  create_table "admins", force: :cascade do |t|
    t.string "email"
    t.string "user_id"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "password_changed_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.string "theme_color", default: "sky", null: false
    t.index ["password_reset_token"], name: "index_admins_on_password_reset_token", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.text "summary"
    t.string "thumbnail"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "draft", default: false, null: false
    t.datetime "published_at"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "name", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_site_settings_on_name", unique: true
  end
end
