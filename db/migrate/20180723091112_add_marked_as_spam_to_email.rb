class AddMarkedAsSpamToEmail < ActiveRecord::Migration[5.2]
  def change
    add_column :emails, :marked_as_spam, :boolean, default: nil
  end
end
