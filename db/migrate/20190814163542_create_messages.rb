class CreateMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :messages, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.text :sender_message_id
      t.text :title, null: false
      t.text :url
      t.text :body, null: false
      t.json :links, default: {}, null: false
      t.json :tags, default: {}, null: false
      t.string :document_type
      t.string :email_document_supertype
      t.string :government_document_supertype
      t.datetime :processed_at
      t.string :signon_user_uid
      t.string :govuk_request_id, null: false
      t.integer :priority, default: 0, null: false
      t.timestamps

      t.index :sender_message_id, unique: true
    end
  end
end
