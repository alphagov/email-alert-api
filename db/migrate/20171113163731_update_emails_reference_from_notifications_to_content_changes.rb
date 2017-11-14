class UpdateEmailsReferenceFromNotificationsToContentChanges < ActiveRecord::Migration[5.1]
  def change
    remove_column :emails, :notification_id, :integer
  end
end
