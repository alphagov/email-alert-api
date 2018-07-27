class DropUnusedIndexes < ActiveRecord::Migration[5.2]
  def up
    remove_index :content_changes, name: :index_content_changes_on_updated_at
    remove_index :delivery_attempts, name: :index_delivery_attempts_on_updated_at
    remove_index :emails, name: :index_emails_on_status
    remove_index :emails, name: :index_emails_on_status_and_archived_at
    remove_index :emails, name: :index_emails_on_updated_at
    remove_index :subscription_contents, name: :index_subscription_contents_on_created_at if index_exists?(:subscription_contents, :index_subscription_contents_on_created_at)
    remove_index :subscriptions, name: :index_subscriptions_on_updated_at
  end
end
