class AddProcessedAtToDigestRuns < ActiveRecord::Migration[6.0]
  def change
    add_column :digest_runs, :processed_at, :datetime
  end
end
