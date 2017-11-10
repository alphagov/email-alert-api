class AddEnabledFlagToSubscriberLists < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriber_lists, :enabled, :boolean, default: true, null: false
  end
end
