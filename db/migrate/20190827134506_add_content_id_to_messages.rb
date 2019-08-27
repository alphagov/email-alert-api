class AddContentIdToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :content_id, :uuid
  end
end
