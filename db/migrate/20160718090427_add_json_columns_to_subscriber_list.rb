class AddJSONColumnsToSubscriberList < ActiveRecord::Migration
  def change
    add_column :subscriber_lists, :tags_json, :json, default: {}, null: false
    add_column :subscriber_lists, :links_json, :json, default: {}, null: false
  end
end
