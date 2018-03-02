class IndexArchivedAtOnEmails < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :emails, :archived_at, algorithm: :concurrently
  end
end
