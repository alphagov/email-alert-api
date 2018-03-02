class AddUniqueIndexOnActiveSubscriptions < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    add_index :subscriptions,
      %w(subscriber_id subscriber_list_id),
      unique: true,
      where: "(ended_at IS NULL)"
  end
end
