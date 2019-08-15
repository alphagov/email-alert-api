class SubscriptionContentsAcceptNilContentChanges < ActiveRecord::Migration[5.2]
  def change
    change_column_null :subscription_contents, :content_change_id, true
  end
end
