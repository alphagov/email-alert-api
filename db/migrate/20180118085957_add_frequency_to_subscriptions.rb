class AddFrequencyToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :frequency, :integer, null: false, default: 0
  end
end
