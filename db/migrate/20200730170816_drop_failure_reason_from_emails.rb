class DropFailureReasonFromEmails < ActiveRecord::Migration[6.0]
  def change
    remove_index :emails, :failure_reason
    remove_column :emails, :failure_reason, :integer
  end
end
