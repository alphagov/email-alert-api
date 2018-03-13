class RemoveNotificationLog < ActiveRecord::Migration[5.1]
  def change
    drop_table :notification_logs
  end
end
