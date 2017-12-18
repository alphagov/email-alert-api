class CascadeNullifySubscriptionContentsSubscriptions < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :subscription_contents, :subscriptions
    add_foreign_key :subscription_contents, :subscriptions, on_delete: :nullify
  end
end
