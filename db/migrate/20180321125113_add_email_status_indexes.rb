class AddEmailStatusIndexes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :emails, %i[status archived_at], algorithm: :concurrently
    add_index :emails, :status, algorithm: :concurrently
    add_index :emails, :failure_reason, algorithm: :concurrently
  end
end
