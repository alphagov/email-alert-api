class AddForeignKeyIndexesForSubscriberId < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :emails, :subscriber_id, algorithm: :concurrently
    add_index :digest_run_subscribers, :subscriber_id, algorithm: :concurrently
  end
end
