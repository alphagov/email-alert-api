class AddAddressToEmail < ActiveRecord::Migration[5.1]
  def change
    add_column :emails, :address, :string, default: '', null: false
  end
end
