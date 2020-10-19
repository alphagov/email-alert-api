class AddIndexForDigestRunIdOnDigestRunSubscribers < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :digest_run_subscribers, :digest_run_id, algorithm: :concurrently
  end
end
