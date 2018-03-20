class ChangeEmailStatusDefault < ActiveRecord::Migration[5.1]
  def change
    change_column :emails, :status, :integer, default: 0, null: false
  end
end
