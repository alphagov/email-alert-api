class AddIndexToSubscriptionEndedAt < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :subscriptions, :ended_at, algorithm: :concurrently
  end
end
