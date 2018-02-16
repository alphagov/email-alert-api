class AddSubscriptionContentsIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :subscription_contents, :digest_run_subscriber_id
  end
end
