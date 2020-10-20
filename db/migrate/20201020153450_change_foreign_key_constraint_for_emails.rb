class ChangeForeignKeyConstraintForEmails < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :emails, :subscribers
    add_foreign_key :emails, :subscribers, on_delete: :restrict
  end
end
