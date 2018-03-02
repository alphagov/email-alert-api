class AddForeignKeyOnDeletes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_foreign_key :matched_content_changes, :content_changes, on_delete: :cascade
    add_foreign_key :matched_content_changes, :subscriber_lists, on_delete: :cascade

    add_foreign_key :subscription_contents, :emails, on_delete: :cascade
    add_foreign_key :subscription_contents, :subscriptions, on_delete: :restrict

    add_foreign_key :subscriptions, :subscriber_lists, on_delete: :restrict
    add_foreign_key :subscriptions, :subscribers, on_delete: :restrict
  end
end
