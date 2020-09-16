class RemoveFinishedSendingAtFromEmails < ActiveRecord::Migration[6.0]
  def change
    remove_index :emails, :finished_sending_at
    remove_column :emails, :finished_sending_at, :datetime
  end
end
