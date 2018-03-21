class IndexCreatedUpdatedUuidTables < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    %i[emails delivery_attempts subscriptions content_changes].each do |table|
      add_index table, :created_at, algorithm: :concurrently
      add_index table, :updated_at, algorithm: :concurrently
    end
  end
end
