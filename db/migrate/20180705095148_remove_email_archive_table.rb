class RemoveEmailArchiveTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :email_archives
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
