class AddStatusAndFailureReasonToEmails < ActiveRecord::Migration[5.1]
  def change
    add_column :emails, :status, :integer
    add_column :emails, :failure_reason, :integer
  end
end
