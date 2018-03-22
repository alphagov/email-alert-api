class ChangeEmailStatusDefault < ActiveRecord::Migration[5.1]
  def up
    change_column :emails, :status, :integer, default: 0, null: false
  end

  def down
    change_column :emails, :status, :integer, default: nil, null: true
  end
end
