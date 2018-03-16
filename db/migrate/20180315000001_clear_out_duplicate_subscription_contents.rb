class ClearOutDuplicateSubscriptionContents < ActiveRecord::Migration[5.1]
  def up
    all_ids = SubscriptionContent.pluck(:id)

    ids_to_keep = SubscriptionContent
      .group(:content_change_id, :subscription_id)
      .pluck("MIN(id)")

    ids_to_delete = all_ids - ids_to_keep

    deleted_count = SubscriptionContent.where(id: ids_to_delete).delete_all

    puts "deleted #{deleted_count} rows"
  end
end
