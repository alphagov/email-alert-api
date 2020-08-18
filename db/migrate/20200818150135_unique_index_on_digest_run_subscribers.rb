class UniqueIndexOnDigestRunSubscribers < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :digest_run_subscribers,
              %i[digest_run_id subscriber_id],
              unique: true,
              algorithm: :concurrently
  end
end
