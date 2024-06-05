class AddSubscriptionIdToEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :emails, :subscription_id, :uuid, default: nil, null: true
  end
end
