class RemoveMarkedAsSpamFromEmail < ActiveRecord::Migration[6.0]
  def change
    remove_column :emails, :marked_as_spam, :boolean
  end
end
