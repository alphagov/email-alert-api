class AddNullFalseToTagsField < ActiveRecord::Migration
  def change
    change_column :subscriber_lists, :tags, :hstore, null: false, default: {}
  end
end
