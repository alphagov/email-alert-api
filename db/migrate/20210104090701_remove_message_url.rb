class RemoveMessageUrl < ActiveRecord::Migration[6.0]
  def change
    remove_column :messages, :url, :string
  end
end
