class AddDigestRunSubscriberIdToSubscriptionContents < ActiveRecord::Migration[5.1]
  def change
    add_column :subscription_contents, :digest_run_subscriber_id, :integer
    add_foreign_key :subscription_contents, :digest_run_subscribers, on_delete: :cascade
  end
end
