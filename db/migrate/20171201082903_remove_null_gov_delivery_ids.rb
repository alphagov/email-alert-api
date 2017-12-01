class RemoveNullGovDeliveryIds < ActiveRecord::Migration[5.1]
  def up
    SubscriberList.where(gov_delivery_id: nil).destroy_all
  end
end
