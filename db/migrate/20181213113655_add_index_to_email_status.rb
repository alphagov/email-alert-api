class AddIndexToEmailStatus < ActiveRecord::Migration[5.2]
  def change
    add_index :emails, :status
  end
end
