class MakeSubscriberListGovDeliveryIdNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null :subscriber_lists, :gov_delivery_id, false
  end
end
