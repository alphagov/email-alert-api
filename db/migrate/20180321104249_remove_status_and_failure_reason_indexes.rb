class RemoveStatusAndFailureReasonIndexes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    remove_index :emails, column: :status, algorithm: :concurrently
    remove_index :emails, column: :failure_reason, algorithm: :concurrently
  end
end
