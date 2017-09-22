class RemoveRedundantColumnsAfterQ2Mission < ActiveRecord::Migration[5.1]
  def change
    remove_column :notification_logs, :enabled_gov_delivery_ids
    remove_column :notification_logs, :disabled_gov_delivery_ids
    remove_column :notification_logs, :emailing_app

    remove_column :subscriber_lists, :enabled

    # A list of migrated gov_delivery_ids is available in Google Drive:
    # https://drive.google.com/a/digital.cabinet-office.gov.uk/file/d/0B6JKO797SExjMm90eTB0ekxURTg/view
    remove_column :subscriber_lists, :migrated_from_gov_uk_delivery
  end
end
