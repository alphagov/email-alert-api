class AddMatchedContentChange < ActiveRecord::Migration[5.1]
  def change
    create_table :matched_content_changes do |t|
      t.references :content_change, null: false, foreign_key: true
      t.references :subscriber_list, null: false, foreign_key: true
      t.timestamps
    end

    add_index :matched_content_changes, %i(content_change_id subscriber_list_id), unique: true, name: "index_matched_content_changes_content_change_subscriber_list"
  end
end
