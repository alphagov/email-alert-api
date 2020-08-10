class RemoveSubscriberCountFromDigestRun < ActiveRecord::Migration[6.0]
  def up
    remove_column :digest_runs, :subscriber_count
  end
end
