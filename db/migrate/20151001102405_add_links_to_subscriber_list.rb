class AddLinksToSubscriberList < ActiveRecord::Migration[4.2]
  def change
    #add_column :subscriber_lists, :links, :hstore, null: false, default: {}

    #add_index :subscriber_lists, :links, using: :gin
  end
end
