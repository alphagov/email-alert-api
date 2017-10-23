class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.uuid :content_id, null: false
      t.text :title, null: false
      t.text :base_path, null: false
      t.text :change_note, null: false
      t.text :description, null: false
      t.json :links, null: false, default: {}
      t.json :tags, null: false, default: {}
      t.datetime :public_updated_at, null: false
      t.string :email_document_supertype, null: false
      t.string :government_document_supertype, null: false
      t.string :govuk_request_id, null: false
      t.string :document_type, null: false
      t.string :publishing_app, null: false
      t.timestamps
    end
  end
end
