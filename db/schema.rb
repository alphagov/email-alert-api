# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170327104203) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "notification_logs", id: :serial, force: :cascade do |t|
    t.string "govuk_request_id", default: ""
    t.string "content_id", default: ""
    t.datetime "public_updated_at"
    t.json "links", default: {}
    t.json "tags", default: {}
    t.string "document_type", default: ""
    t.string "emailing_app", default: "", null: false
    t.json "gov_delivery_ids", default: []
    t.string "publishing_app", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "enabled_gov_delivery_ids", default: []
    t.json "disabled_gov_delivery_ids", default: []
    t.string "email_document_supertype", default: ""
    t.string "government_document_supertype", default: ""
    t.index ["content_id", "public_updated_at"], name: "index_notification_logs_on_content_id_and_public_updated_at"
    t.index ["govuk_request_id"], name: "index_notification_logs_on_govuk_request_id"
  end

  create_table "subscriber_lists", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.string "gov_delivery_id", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "document_type", default: "", null: false
    t.json "tags", default: {}, null: false
    t.json "links", default: {}, null: false
    t.boolean "enabled", default: true, null: false
    t.string "email_document_supertype", default: "", null: false
    t.string "government_document_supertype", default: "", null: false
    t.boolean "migrated_from_gov_uk_delivery", default: false, null: false
  end

end
