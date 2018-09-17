class RemoveEndedEmailIdForeignKeyFromSubscriptions < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :subscriptions, :emails
  end
end
