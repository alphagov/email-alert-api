class AddCaseInsensitiveIndexOnEmails < ActiveRecord::Migration[5.1]
  def change
    remove_index :subscribers, :address, unique: true
    add_index :subscribers, 'LOWER(address)', name: 'index_subscribers_on_lower_address', unique: true
  end
end
