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

ActiveRecord::Schema.define(version: 2019_03_13_155146) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "content_changes", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
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
    t.datetime "processed_at"
    t.integer "priority", default: 0
    t.string "signon_user_uid"
    t.text "footnote", default: "", null: false
    t.index ["created_at"], name: "index_content_changes_on_created_at"
    t.index ["processed_at"], name: "index_content_changes_on_processed_at"
  end

  create_table "delivery_attempts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.integer "status", null: false
    t.integer "provider", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signon_user_uid"
    t.uuid "email_id", null: false
    t.datetime "completed_at"
    t.datetime "sent_at"
    t.index ["created_at"], name: "index_delivery_attempts_on_created_at"
    t.index ["email_id", "updated_at"], name: "index_delivery_attempts_on_email_id_and_updated_at"
    t.index ["email_id"], name: "index_delivery_attempts_on_email_id"
  end

  create_table "digest_run_subscribers", force: :cascade do |t|
    t.integer "digest_run_id", null: false
    t.integer "subscriber_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "digest_runs", force: :cascade do |t|
    t.date "date", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "range", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "subscriber_count"
    t.index ["completed_at"], name: "index_digest_runs_on_completed_at"
    t.index ["created_at"], name: "index_digest_runs_on_created_at"
  end

  create_table "emails", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "subject", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address", null: false
    t.datetime "finished_sending_at"
    t.datetime "archived_at"
    t.bigint "subscriber_id"
    t.integer "status", default: 0, null: false
    t.integer "failure_reason"
    t.boolean "marked_as_spam"
    t.index ["address"], name: "index_emails_on_address"
    t.index ["archived_at"], name: "index_emails_on_archived_at"
    t.index ["created_at"], name: "index_emails_on_created_at"
    t.index ["failure_reason"], name: "index_emails_on_failure_reason"
    t.index ["finished_sending_at"], name: "index_emails_on_finished_sending_at"
  end

  create_table "matched_content_changes", force: :cascade do |t|
    t.bigint "subscriber_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "content_change_id", null: false
    t.index ["content_change_id", "subscriber_list_id"], name: "index_matched_content_changes_content_change_subscriber_list", unique: true
    t.index ["content_change_id"], name: "index_matched_content_changes_on_content_change_id"
    t.index ["subscriber_list_id"], name: "index_matched_content_changes_on_subscriber_list_id"
  end

  create_table "subscriber_lists", id: :serial, force: :cascade do |t|
    t.string "title", limit: 10000, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "document_type", default: "", null: false
    t.json "tags", default: {}, null: false
    t.json "links", default: {}, null: false
    t.string "email_document_supertype", default: "", null: false
    t.string "government_document_supertype", default: "", null: false
    t.string "signon_user_uid"
    t.string "slug", limit: 10000, null: false
    t.string "content_purpose_supergroup", limit: 100
    t.index ["document_type"], name: "index_subscriber_lists_on_document_type"
    t.index ["email_document_supertype"], name: "index_subscriber_lists_on_email_document_supertype"
    t.index ["government_document_supertype"], name: "index_subscriber_lists_on_government_document_supertype"
    t.index ["slug"], name: "index_subscriber_lists_on_slug", unique: true
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signon_user_uid"
    t.datetime "deactivated_at"
    t.index "lower((address)::text)", name: "index_subscribers_on_lower_address", unique: true
  end

  create_table "subscription_contents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "digest_run_subscriber_id"
    t.uuid "email_id"
    t.uuid "subscription_id", null: false
    t.uuid "content_change_id", null: false
    t.index ["content_change_id"], name: "index_subscription_contents_on_content_change_id"
    t.index ["digest_run_subscriber_id"], name: "index_subscription_contents_on_digest_run_subscriber_id"
    t.index ["email_id"], name: "index_subscription_contents_on_email_id"
    t.index ["subscription_id", "content_change_id"], name: "index_subscription_contents_on_subscription_and_content_change", unique: true
    t.index ["subscription_id"], name: "index_subscription_contents_on_subscription_id"
  end

  create_table "subscriptions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.bigint "subscriber_id", null: false
    t.bigint "subscriber_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "frequency", default: 0, null: false
    t.string "signon_user_uid"
    t.integer "source", default: 0, null: false
    t.datetime "ended_at"
    t.integer "ended_reason"
    t.uuid "ended_email_id"
    t.index ["created_at"], name: "index_subscriptions_on_created_at"
    t.index ["subscriber_id", "subscriber_list_id"], name: "index_subscriptions_on_subscriber_id_and_subscriber_list_id", unique: true, where: "(ended_at IS NULL)"
    t.index ["subscriber_id"], name: "index_subscriptions_on_subscriber_id"
    t.index ["subscriber_list_id"], name: "index_subscriptions_on_subscriber_list_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "permissions", default: [], array: true
    t.boolean "remotely_signed_out", default: false
    t.boolean "disabled", default: false
  end

  add_foreign_key "delivery_attempts", "emails", on_delete: :cascade
  add_foreign_key "digest_run_subscribers", "digest_runs", on_delete: :cascade
  add_foreign_key "digest_run_subscribers", "subscribers", on_delete: :cascade
  add_foreign_key "emails", "subscribers", name: "emails_subscriber_id_fk", on_delete: :cascade
  add_foreign_key "matched_content_changes", "content_changes", on_delete: :cascade
  add_foreign_key "matched_content_changes", "subscriber_lists", on_delete: :cascade
  add_foreign_key "subscription_contents", "content_changes", on_delete: :restrict
  add_foreign_key "subscription_contents", "digest_run_subscribers", on_delete: :cascade
  add_foreign_key "subscription_contents", "emails", on_delete: :cascade
  add_foreign_key "subscription_contents", "subscriptions", on_delete: :restrict
  add_foreign_key "subscriptions", "subscriber_lists", on_delete: :restrict
  add_foreign_key "subscriptions", "subscribers", on_delete: :restrict
end
