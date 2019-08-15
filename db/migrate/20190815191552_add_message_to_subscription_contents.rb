class AddMessageToSubscriptionContents < ActiveRecord::Migration[5.2]
  def change
    add_reference :subscription_contents,
                  :message,
                  type: :uuid,
                  foreign_key: { on_delete: :restrict },
                  index: false
  end
end
