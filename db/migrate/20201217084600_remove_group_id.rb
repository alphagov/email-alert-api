class RemoveGroupId < ActiveRecord::Migration[6.0]
  def change
    remove_column :subscriber_lists, :group_id, type: :string
  end
end
