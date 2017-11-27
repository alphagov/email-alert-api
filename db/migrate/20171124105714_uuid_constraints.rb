class UuidConstraints < ActiveRecord::Migration[5.1]
  def change
    change_column_null :subscriptions, :uuid, false

    remove_index :subscriptions, :uuid
    add_index :subscriptions, :uuid, unique: true
  end
end
