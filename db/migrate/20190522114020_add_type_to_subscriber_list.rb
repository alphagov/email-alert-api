class AddTypeToSubscriberList < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :type, :string
  end
end
