class IndexFinishedSendingAtOnEmails < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :emails, :finished_sending_at, algorithm: :concurrently
  end
end
