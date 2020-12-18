class RemoveDescriptionField < ActiveRecord::Migration[6.0]
  def change
    remove_column :subscriber_lists, :description, type: :string
  end
end
