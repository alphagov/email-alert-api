class AddFootnoteToContentChange < ActiveRecord::Migration[5.1]
  def change
    add_column :content_changes, :footnote, :text, null: false, default: ""
  end
end
