class AddExportedAtToEmailArchives < ActiveRecord::Migration[5.2]
  def change
    add_column :email_archives, :exported_at, :datetime
  end
end
