class AddUniqueIndexOnSubscriptionContent < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :subscription_contents,
      %w(subscription_id content_change_id),
      name: "index_subscription_contents_on_subscription_and_content_change",
      unique: true,
      algorithm: :concurrently
  end
end
