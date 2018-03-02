class AddArchivedAtToEmails < ActiveRecord::Migration[5.1]
  def change
    add_column :emails, :archived_at, :datetime
  end
end
