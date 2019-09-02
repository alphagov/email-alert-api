class AddIndexesToSubscriberListDigests < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :subscriber_lists,
              :tags_digest,
              algorithm: :concurrently
    add_index :subscriber_lists,
              :links_digest,
              algorithm: :concurrently
  end
end
