class AddContentIdToSubscriberLists < ActiveRecord::Migration[6.1]
  def change
    add_column :subscriber_lists, :content_id, :uuid
    add_index :subscriber_lists, :content_id
  end
end
