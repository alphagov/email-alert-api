class AddLockVersionToSubscriptionContent < ActiveRecord::Migration[5.1]
  def change
    add_column :subscription_contents, :lock_version, :integer, null: false, default: 0
  end
end
