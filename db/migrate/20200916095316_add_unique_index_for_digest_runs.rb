class AddUniqueIndexForDigestRuns < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :digest_runs, %i[date range], unique: true, algorithm: :concurrently
  end
end
