class AddUniqueIndexOnReference < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :delivery_attempts, :reference, unique: true, algorithm: :concurrently
  end
end
