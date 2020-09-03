class AddSentAtToEmails < ActiveRecord::Migration[6.0]
  def change
    add_column :emails, :sent_at, :datetime
  end
end
