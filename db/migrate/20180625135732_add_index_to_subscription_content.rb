class AddIndexToSubscriptionContent < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :subscription_contents, :created_at, algorithm: :concurrently
  end
end
