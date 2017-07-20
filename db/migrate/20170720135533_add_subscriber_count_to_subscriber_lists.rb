class AddSubscriberCountToSubscriberLists < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriber_lists, :subscriber_count, :integer
  end
end
