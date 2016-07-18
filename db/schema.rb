# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160718090427) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "subscriber_lists", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.string   "gov_delivery_id", limit: 255
    t.hstore   "tags",                        default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "links",                       default: {}, null: false
    t.string   "document_type",               default: "", null: false
    t.json     "tags_json",                   default: {}, null: false
    t.json     "links_json",                  default: {}, null: false
  end

  add_index "subscriber_lists", ["links"], name: "index_subscriber_lists_on_links", using: :gin
  add_index "subscriber_lists", ["tags"], name: "index_subscriber_lists_on_tags", using: :gin

end
