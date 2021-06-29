class AddGovukAccountIdToSubscribers < ActiveRecord::Migration[6.1]
  def change
    add_column :subscribers, :govuk_account_id, :string
    add_index :subscribers, :govuk_account_id
  end
end
