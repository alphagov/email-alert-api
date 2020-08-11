class AddSubscriberIndexToDigestRunSubscriber < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :digest_run_subscribers, :subscriber_id, algorithm: :concurrently
  end
end
