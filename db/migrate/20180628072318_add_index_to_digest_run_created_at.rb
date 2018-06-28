class AddIndexToDigestRunCreatedAt < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :digest_runs, :created_at, algorithm: :concurrently
  end
end
