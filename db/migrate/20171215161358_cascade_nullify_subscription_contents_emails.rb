class CascadeNullifySubscriptionContentsEmails < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :subscription_contents, :emails
    add_foreign_key :subscription_contents, :emails, on_delete: :nullify
  end
end
