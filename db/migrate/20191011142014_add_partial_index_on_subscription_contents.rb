class AddPartialIndexOnSubscriptionContents < ActiveRecord::Migration[5.2]
  def change
    add_index(
      :subscription_contents,
      :subscription_id,
      where: "email_id IS NULL",
      name: "partial_index_subscription_contents_on_subscription_id",
    )
  end
end
