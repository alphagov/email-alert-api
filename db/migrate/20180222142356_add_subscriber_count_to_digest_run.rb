class AddSubscriberCountToDigestRun < ActiveRecord::Migration[5.1]
  def change
    add_column :digest_runs, :subscriber_count, :integer
  end
end
