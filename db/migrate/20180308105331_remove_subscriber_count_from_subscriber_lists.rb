class RemoveSubscriberCountFromSubscriberLists < ActiveRecord::Migration[5.1]
  def change
    remove_column :subscriber_lists, :subscriber_count
  end
end
