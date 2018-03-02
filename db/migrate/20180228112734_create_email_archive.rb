class CreateEmailArchive < ActiveRecord::Migration[5.1]
  def change
    create_table :email_archives, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string "subject", null: false
      t.bigint "subscriber_id"
      t.json "content_change"
      t.boolean "sent", null: false
      t.datetime "created_at", null: false
      t.datetime "archived_at", null: false
      t.datetime "finished_sending_at", null: false
    end
  end
end
