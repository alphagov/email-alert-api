class RemoveUniqueIndexOnSubscriptions < ActiveRecord::Migration[5.1]
  def up
    remove_index :subscriptions, %w(subscriber_id subscriber_list_id)
  end
end
