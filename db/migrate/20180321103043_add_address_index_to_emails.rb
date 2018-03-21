class AddAddressIndexToEmails < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :emails, :address, algorithm: :concurrently
  end
end
