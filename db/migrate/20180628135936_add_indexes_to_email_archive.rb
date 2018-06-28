class AddIndexesToEmailArchive < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
    add_index :email_archives, :finished_sending_at, algorithm: :concurrently
    add_index :email_archives, :exported_at, algorithm: :concurrently
  end
end
