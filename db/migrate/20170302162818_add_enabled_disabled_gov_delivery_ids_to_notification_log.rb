class AddEnabledDisabledGovDeliveryIdsToNotificationLog < ActiveRecord::Migration[4.2]
  def change
    add_column :notification_logs, :enabled_gov_delivery_ids, :json, default: []
    add_column :notification_logs, :disabled_gov_delivery_ids, :json, default: []
  end
end
