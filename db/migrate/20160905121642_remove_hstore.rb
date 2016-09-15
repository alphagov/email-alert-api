class RemoveHstore < ActiveRecord::Migration
  def up
    remove_column :subscriber_lists, :tags
    remove_column :subscriber_lists, :links
    add_column :subscriber_lists, :tags, :json, default: {}, null: false
    add_column :subscriber_lists, :links, :json, default: {}, null: false

    SubscriberList.connection.update("UPDATE subscriber_lists SET tags = tags_json, links = links_json")
  end

  def down
    remove_column :subscriber_lists, :tags
    remove_column :subscriber_lists, :links
    add_column :subscriber_lists, :tags, :hstore, default: {}, null: false
    add_column :subscriber_lists, :links, :hstore, default: {}, null: false

    SubscriberList.all.each do |subscriber_list|
      subscriber_list.update_columns(
        tags: subscriber_list.tags_json,
        links: subscriber_list.links_json,
      )
    end
  end
end
