class RemoveIncorrectForeignKeys < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :matched_content_changes, :content_changes
    remove_foreign_key :matched_content_changes, :subscriber_lists

    remove_foreign_key :subscription_contents, :emails
    remove_foreign_key :subscription_contents, :subscriptions

    remove_foreign_key :subscriptions, :subscriber_lists
    remove_foreign_key :subscriptions, :subscribers
  end
end
