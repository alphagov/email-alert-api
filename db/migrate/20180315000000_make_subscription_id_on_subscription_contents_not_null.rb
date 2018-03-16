class MakeSubscriptionIdOnSubscriptionContentsNotNull < ActiveRecord::Migration[5.1]
  def up
    SubscriptionContent.where(subscription_id: nil).delete_all

    change_column_null :subscription_contents, :subscription_id, false
  end
end
