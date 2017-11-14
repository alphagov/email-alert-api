class RenameNotificationsToContentChanges < ActiveRecord::Migration[5.1]
  def change
    rename_table :notifications, :content_changes
  end
end
