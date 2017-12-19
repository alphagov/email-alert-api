class MakeSubscriberListTitleUnique < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :subscriber_lists, [:title], unique: true, algorithm: :concurrently
  end
end
