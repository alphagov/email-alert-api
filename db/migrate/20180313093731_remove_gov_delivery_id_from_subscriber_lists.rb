class RemoveGovDeliveryIdFromSubscriberLists < ActiveRecord::Migration[5.1]
  def up
    remove_column :subscriber_lists, :gov_delivery_id
  end
end
