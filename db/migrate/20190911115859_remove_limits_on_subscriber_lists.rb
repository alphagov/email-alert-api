class RemoveLimitsOnSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    change_column :subscriber_lists, :title, :string, limit: nil
    change_column :subscriber_lists, :slug, :string, limit: nil
  end
end
