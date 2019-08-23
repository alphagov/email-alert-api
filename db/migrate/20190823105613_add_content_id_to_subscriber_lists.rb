class AddContentIdToSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :content_id, :uuid
  end
end
