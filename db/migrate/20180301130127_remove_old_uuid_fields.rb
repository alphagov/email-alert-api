class RemoveOldUuidFields < ActiveRecord::Migration[5.1]
  def up
    remove_column :delivery_attempts, :reference
    remove_column :subscriptions, :uuid
  end
end
