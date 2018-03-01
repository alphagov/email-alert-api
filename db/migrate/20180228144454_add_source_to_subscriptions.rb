class AddSourceToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :source, :integer, default: 0, null: false
  end
end
