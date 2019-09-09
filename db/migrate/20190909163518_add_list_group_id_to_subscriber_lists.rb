class AddListGroupIdToSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :list_group_id, :string
  end
end
