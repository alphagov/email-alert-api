class AddIndexToContentChangeProcessedAt < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :content_changes, :processed_at, algorithm: :concurrently
  end
end
