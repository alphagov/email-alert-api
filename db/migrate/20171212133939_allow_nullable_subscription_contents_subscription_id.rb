class AllowNullableSubscriptionContentsSubscriptionId < ActiveRecord::Migration[5.1]
  def change
    change_column_null :subscription_contents, :subscription_id, true
  end
end
