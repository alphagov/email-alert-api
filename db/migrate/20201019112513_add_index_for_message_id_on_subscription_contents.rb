class AddIndexForMessageIdOnSubscriptionContents < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :subscription_contents, :message_id, algorithm: :concurrently
  end
end
