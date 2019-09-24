class AddDescriptionToSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :description, :string, null: false, default: ""
  end
end
