class AddProcessedAtToEmails < ActiveRecord::Migration[5.1]
  def change
    add_column :emails, :processed_at, :datetime
  end
end
