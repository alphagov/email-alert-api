class AddPriorityToChangeContent < ActiveRecord::Migration[5.1]
  def change
    add_column :content_changes, :priority, :integer, default: 0
  end
end
