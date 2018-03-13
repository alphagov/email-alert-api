class MakeSubscriberListGovDeliveryIdLonger < ActiveRecord::Migration[5.1]
  def change
    change_column :subscriber_lists, :gov_delivery_id, :string, limit: 1000
  end
end
