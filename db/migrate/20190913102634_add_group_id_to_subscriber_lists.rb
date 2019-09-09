class AddGroupIdToSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :group_id, :string
  end
end
