class AddDeletedAtToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :deleted_at, :datetime
  end
end
