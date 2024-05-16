class AddLastAlertedAt < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriber_lists, :last_alerted_at, :datetime, default: nil, null: true
  end
end
