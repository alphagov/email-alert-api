class ValidateMessageToSubscriptionContents < ActiveRecord::Migration[5.2]
  def changes
    validate_foreign_key :subscription_contents, :messages
  end
end
