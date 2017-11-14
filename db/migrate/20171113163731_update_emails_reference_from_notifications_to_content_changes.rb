class UpdateEmailsReferenceFromNotificationsToContentChanges < ActiveRecord::Migration[5.1]
  def change
    remove_column :emails, :notification_id
    add_reference(:emails, :content_change, null: false, foreign_key: true)
  end
end
