class MakeSubscriptionIdOnSubscriptionContentsNotNull < ActiveRecord::Migration[5.1]
  def up
    deleted_count = SubscriptionContent.where(subscription_id: nil).delete_all

    puts "deleted #{deleted_count} rows"

    change_column_null :subscription_contents, :subscription_id, false
  end
end
