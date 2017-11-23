class AddUuidToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :uuid, :uuid
    add_index :subscriptions, :uuid
  end
end
