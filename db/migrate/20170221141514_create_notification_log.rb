class CreateNotificationLog < ActiveRecord::Migration[4.2]
  def change
    create_table :notification_logs do |t|
      t.string :govuk_request_id, index: true, default: ''
      t.string :content_id, default: ''
      t.datetime :public_updated_at
      t.json :links, default: {}
      t.json :tags, default: {}
      t.string :document_type, default: ''
      t.string :emailing_app, default: '', null: false
      t.json :gov_delivery_ids, default: []
      t.string :publishing_app, default: ''

      t.timestamps null: false
    end

    add_index :notification_logs, %i[content_id public_updated_at]
  end
end
