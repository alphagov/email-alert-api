class AddFinishedSendingAtToEmails < ActiveRecord::Migration[5.1]
  def change
    add_column :emails, :finished_sending_at, :datetime
  end
end
