class AddProcessedAtToContentChange < ActiveRecord::Migration[5.1]
  def change
    add_column :content_changes, :processed_at, :datetime
  end
end
