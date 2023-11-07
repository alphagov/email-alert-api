class UpdateEmailsAddNotifyStatusAndIdIndex < ActiveRecord::Migration[7.1]
  def change
    add_column :emails, :notify_status, :string
    add_index :emails, :notify_status
    add_index :emails, :id
  end
end
