class AddNullFalseToTagsField < ActiveRecord::Migration[4.2]
  def change
    #change_column :subscriber_lists, :tags, :hstore, null: false, default: {}
  end
end
