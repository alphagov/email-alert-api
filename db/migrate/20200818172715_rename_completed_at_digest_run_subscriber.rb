class RenameCompletedAtDigestRunSubscriber < ActiveRecord::Migration[6.0]
  def change
    rename_column :digest_run_subscribers, :completed_at, :processed_at
  end
end
