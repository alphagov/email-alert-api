class AddEndedEmailIdToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :ended_email_id, :uuid, null: true
    add_foreign_key(
      :subscriptions,
      :emails,
      column: :ended_email_id,
    )
  end
end
