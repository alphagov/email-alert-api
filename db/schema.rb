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

ActiveRecord::Schema[7.1].define(version: 2024_04_11_100041) do
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
    t.datetime "public_updated_at", precision: nil, null: false
    t.string "email_document_supertype", null: false
    t.string "government_document_supertype", null: false
    t.string "govuk_request_id", null: false
    t.string "document_type", null: false
    t.string "publishing_app", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "processed_at", precision: nil
    t.integer "priority", default: 0
    t.string "signon_user_uid"
    t.text "footnote", default: "", null: false
    t.index ["created_at"], name: "index_content_changes_on_created_at"
    t.index ["processed_at"], name: "index_content_changes_on_processed_at"
  end

  create_table "digest_run_subscribers", force: :cascade do |t|
    t.integer "digest_run_id", null: false
    t.integer "subscriber_id", null: false
    t.datetime "processed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["digest_run_id", "subscriber_id"], name: "index_digest_run_subscribers_on_digest_run_id_and_subscriber_id", unique: true
    t.index ["digest_run_id"], name: "index_digest_run_subscribers_on_digest_run_id"
    t.index ["subscriber_id"], name: "index_digest_run_subscribers_on_subscriber_id"
  end

  create_table "digest_runs", force: :cascade do |t|
    t.date "date", null: false
    t.datetime "starts_at", precision: nil, null: false
    t.datetime "ends_at", precision: nil, null: false
    t.integer "range", null: false
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "processed_at", precision: nil
    t.index ["completed_at"], name: "index_digest_runs_on_completed_at"
    t.index ["created_at"], name: "index_digest_runs_on_created_at"
    t.index ["date", "range"], name: "index_digest_runs_on_date_and_range", unique: true
  end

  create_table "emails", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text "subject", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "address", null: false
    t.bigint "subscriber_id"
    t.integer "status", default: 0, null: false
    t.datetime "sent_at", precision: nil
    t.uuid "content_id"
    t.string "notify_status"
    t.index ["address"], name: "index_emails_on_address"
    t.index ["content_id"], name: "index_emails_on_content_id"
    t.index ["created_at"], name: "index_emails_on_created_at"
    t.index ["id"], name: "index_emails_on_id"
    t.index ["notify_status"], name: "index_emails_on_notify_status"
    t.index ["subscriber_id"], name: "index_emails_on_subscriber_id"
  end

  create_table "matched_content_changes", force: :cascade do |t|
    t.bigint "subscriber_list_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "content_change_id", null: false
    t.index ["content_change_id", "subscriber_list_id"], name: "index_matched_content_changes_content_change_subscriber_list", unique: true
    t.index ["content_change_id"], name: "index_matched_content_changes_on_content_change_id"
    t.index ["subscriber_list_id"], name: "index_matched_content_changes_on_subscriber_list_id"
  end

  create_table "matched_messages", force: :cascade do |t|
    t.uuid "message_id", null: false
    t.bigint "subscriber_list_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["message_id", "subscriber_list_id"], name: "index_matched_messages_on_message_id_and_subscriber_list_id", unique: true
    t.index ["message_id"], name: "index_matched_messages_on_message_id"
    t.index ["subscriber_list_id"], name: "index_matched_messages_on_subscriber_list_id"
  end

  create_table "messages", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.text "sender_message_id"
    t.text "title", null: false
    t.text "body", null: false
    t.datetime "processed_at", precision: nil
    t.string "signon_user_uid"
    t.string "govuk_request_id", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.json "criteria_rules"
    t.boolean "omit_footer_unsubscribe_link", default: false, null: false
    t.boolean "override_subscription_frequency_to_immediate", default: false, null: false
    t.index ["sender_message_id"], name: "index_messages_on_sender_message_id", unique: true
  end

  create_table "subscriber_list_audits", force: :cascade do |t|
    t.bigint "subscriber_list_id", null: false
    t.integer "reference_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscriber_list_id"], name: "index_subscriber_list_audits_on_subscriber_list_id"
  end

  create_table "subscriber_lists", id: :serial, force: :cascade do |t|
    t.text "title", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "document_type", default: "", null: false
    t.json "tags", default: {}, null: false
    t.json "links", default: {}, null: false
    t.string "email_document_supertype", default: "", null: false
    t.string "government_document_supertype", default: "", null: false
    t.string "signon_user_uid"
    t.string "slug", null: false
    t.text "url"
    t.string "tags_digest"
    t.string "links_digest"
    t.uuid "content_id"
    t.text "description"
    t.datetime "last_audited_at"
    t.index ["content_id"], name: "index_subscriber_lists_on_content_id"
    t.index ["document_type"], name: "index_subscriber_lists_on_document_type"
    t.index ["email_document_supertype"], name: "index_subscriber_lists_on_email_document_supertype"
    t.index ["government_document_supertype"], name: "index_subscriber_lists_on_government_document_supertype"
    t.index ["links_digest"], name: "index_subscriber_lists_on_links_digest"
    t.index ["slug"], name: "index_subscriber_lists_on_slug", unique: true
    t.index ["tags_digest"], name: "index_subscriber_lists_on_tags_digest"
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "signon_user_uid"
    t.string "govuk_account_id"
    t.index "lower((address)::text)", name: "index_subscribers_on_lower_address", unique: true
    t.index ["govuk_account_id"], name: "index_subscribers_on_govuk_account_id"
  end

  create_table "subscription_contents", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "digest_run_subscriber_id"
    t.uuid "email_id"
    t.uuid "subscription_id", null: false
    t.uuid "content_change_id"
    t.uuid "message_id"
    t.index ["content_change_id"], name: "index_subscription_contents_on_content_change_id"
    t.index ["digest_run_subscriber_id"], name: "index_subscription_contents_on_digest_run_subscriber_id"
    t.index ["email_id"], name: "index_subscription_contents_on_email_id"
    t.index ["message_id"], name: "index_subscription_contents_on_message_id"
    t.index ["subscription_id", "content_change_id"], name: "index_subscription_contents_on_subscription_and_content_change", unique: true
    t.index ["subscription_id", "message_id"], name: "index_subscription_contents_on_subscription_id_and_message_id", unique: true
    t.index ["subscription_id"], name: "index_subscription_contents_on_subscription_id"
  end

  create_table "subscriptions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.bigint "subscriber_id", null: false
    t.bigint "subscriber_list_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "frequency", default: 0, null: false
    t.string "signon_user_uid"
    t.integer "source", default: 0, null: false
    t.datetime "ended_at", precision: nil
    t.integer "ended_reason"
    t.uuid "ended_email_id"
    t.index ["created_at"], name: "index_subscriptions_on_created_at"
    t.index ["ended_at"], name: "index_subscriptions_on_ended_at"
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

  add_foreign_key "digest_run_subscribers", "digest_runs", on_delete: :cascade
  add_foreign_key "digest_run_subscribers", "subscribers", on_delete: :cascade
  add_foreign_key "emails", "subscribers", on_delete: :restrict
  add_foreign_key "matched_content_changes", "content_changes", on_delete: :cascade
  add_foreign_key "matched_content_changes", "subscriber_lists", on_delete: :cascade
  add_foreign_key "matched_messages", "messages", on_delete: :cascade
  add_foreign_key "matched_messages", "subscriber_lists", on_delete: :cascade
  add_foreign_key "subscriber_list_audits", "subscriber_lists"
  add_foreign_key "subscription_contents", "content_changes", on_delete: :restrict
  add_foreign_key "subscription_contents", "digest_run_subscribers", on_delete: :cascade
  add_foreign_key "subscription_contents", "emails", on_delete: :cascade
  add_foreign_key "subscription_contents", "messages", on_delete: :restrict
  add_foreign_key "subscription_contents", "subscriptions", on_delete: :restrict
  add_foreign_key "subscriptions", "subscriber_lists", on_delete: :restrict
  add_foreign_key "subscriptions", "subscribers", on_delete: :restrict
end
