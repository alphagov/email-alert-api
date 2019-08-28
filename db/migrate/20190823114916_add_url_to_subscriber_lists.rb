class AddUrlToSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :url, :string
  end
end
