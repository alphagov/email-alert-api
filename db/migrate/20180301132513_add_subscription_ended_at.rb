class AddSubscriptionEndedAt < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :ended_at, :datetime
  end
end
