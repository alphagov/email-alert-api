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

ActiveRecord::Schema.define(version: 20171115162823) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "content_changes", force: :cascade do |t|
    t.uuid "content_id", null: false
    t.text "title", null: false
    t.text "base_path", null: false
    t.text "change_note", null: false
    t.text "description", null: false
    t.json "links", default: {}, null: false
    t.json "tags", default: {}, null: false
    t.datetime "public_updated_at", null: false
    t.string "email_document_supertype", null: false
    t.string "government_document_supertype", null: false
    t.string "govuk_request_id", null: false
    t.string "document_type", null: false
    t.string "publishing_app", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_attempts", force: :cascade do |t|
    t.bigint "email_id", null: false
    t.integer "status", null: false
    t.integer "provider", null: false
    t.string "reference", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_id", "updated_at"], name: "index_delivery_attempts_on_email_id_and_updated_at"
    t.index ["email_id"], name: "index_delivery_attempts_on_email_id"
  end

  create_table "emails", force: :cascade do |t|
    t.string "subject", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address", null: false
  end

  create_table "notification_logs", id: :serial, force: :cascade do |t|
    t.string "govuk_request_id", default: ""
    t.string "content_id", default: ""
    t.datetime "public_updated_at"
    t.json "links", default: {}
    t.json "tags", default: {}
    t.string "document_type", default: ""
    t.json "gov_delivery_ids", default: []
    t.string "publishing_app", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "email_document_supertype", default: "", null: false
    t.string "government_document_supertype", default: "", null: false
    t.integer "subscriber_count"
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_subscribers_on_address", unique: true
  end

  create_table "subscription_contents", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.bigint "content_change_id", null: false
    t.bigint "email_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_change_id"], name: "index_subscription_contents_on_content_change_id"
    t.index ["email_id"], name: "index_subscription_contents_on_email_id"
    t.index ["subscription_id"], name: "index_subscription_contents_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "subscriber_id", null: false
    t.bigint "subscriber_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscriber_id", "subscriber_list_id"], name: "index_subscriptions_on_subscriber_id_and_subscriber_list_id", unique: true
    t.index ["subscriber_id"], name: "index_subscriptions_on_subscriber_id"
    t.index ["subscriber_list_id"], name: "index_subscriptions_on_subscriber_list_id"
  end

  add_foreign_key "delivery_attempts", "emails"
  add_foreign_key "subscription_contents", "content_changes"
  add_foreign_key "subscription_contents", "emails"
  add_foreign_key "subscription_contents", "subscriptions"
  add_foreign_key "subscriptions", "subscriber_lists"
  add_foreign_key "subscriptions", "subscribers", on_delete: :cascade
end
