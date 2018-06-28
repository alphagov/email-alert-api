class AddIndexToDigestRunCompletedAt < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :digest_runs, :completed_at, algorithm: :concurrently
  end
end
