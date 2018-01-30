class CreateDigestRunSubscribers < ActiveRecord::Migration[5.1]
  def change
    create_table :digest_run_subscribers do |t|
      t.integer :digest_run_id, null: false
      t.integer :subscriber_id, null: false
      t.datetime :completed_at
      t.timestamps
    end

    add_foreign_key :digest_run_subscribers, :digest_runs, on_delete: :cascade
    add_foreign_key :digest_run_subscribers, :subscribers, on_delete: :cascade
  end
end
