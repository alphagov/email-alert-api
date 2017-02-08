class RemoveTempJsonFields < ActiveRecord::Migration
  def change
    remove_column :subscriber_lists, :links_json
    remove_column :subscriber_lists, :tags_json
  end
end
