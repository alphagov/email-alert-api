class AddContentIdToEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :emails, :content_id, :uuid
    add_index :emails, :content_id
  end
end
