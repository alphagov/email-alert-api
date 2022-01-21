class AddDescriptionColumnToSubscriberLists < ActiveRecord::Migration[6.1]
  def change
    add_column :subscriber_lists, :description, :text
  end
end
