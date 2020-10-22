class DropDeliveryAttemptsTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :delivery_attempts
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
