class RemoveEmailArchivedAt < ActiveRecord::Migration[6.0]
  def change
    remove_column :emails, :archived_at, :datetime
  end
end
