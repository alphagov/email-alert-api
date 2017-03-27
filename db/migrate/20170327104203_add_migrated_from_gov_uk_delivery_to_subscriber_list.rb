class AddMigratedFromGovUkDeliveryToSubscriberList < ActiveRecord::Migration
  def change
    add_column :subscriber_lists, :migrated_from_gov_uk_delivery, :boolean, default: false, null: false
  end
end
