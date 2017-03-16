class AddEnabledFlagToSubscriberLists < ActiveRecord::Migration
  def change
    add_column :subscriber_lists, :enabled, :boolean, default: true, null: false
  end
end
