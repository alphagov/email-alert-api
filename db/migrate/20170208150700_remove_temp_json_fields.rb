class RemoveTempJsonFields < ActiveRecord::Migration[4.2]
  def change
    remove_column :subscriber_lists, :links_json
    remove_column :subscriber_lists, :tags_json
  end
end
