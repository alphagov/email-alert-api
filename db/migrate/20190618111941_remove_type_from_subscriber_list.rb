class RemoveTypeFromSubscriberList < ActiveRecord::Migration[5.2]
  def change
    remove_column :subscriber_lists, :type, :string
  end
end
