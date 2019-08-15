class UniqueIndexOnSubscriptionContentsMessages < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :subscription_contents,
              %i(subscription_id message_id),
              unique: true,
              algorithm: :concurrently
  end
end
