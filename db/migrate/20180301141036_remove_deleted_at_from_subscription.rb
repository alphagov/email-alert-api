class RemoveDeletedAtFromSubscription < ActiveRecord::Migration[5.1]
  def change
    remove_column :subscriptions, :deleted_at, :datetime
  end
end
