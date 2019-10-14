class RemovePartialIndexOnSubscriptionContents < ActiveRecord::Migration[5.2]
  def change
    remove_index(
      :subscription_contents,
      name: "partial_index_subscription_contents_on_subscription_id",
    )
  end
end
