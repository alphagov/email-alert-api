class MakeSubscriberAddressUnique < ActiveRecord::Migration[5.1]
  def change
    add_index :subscribers, :address, unique: true
  end
end
