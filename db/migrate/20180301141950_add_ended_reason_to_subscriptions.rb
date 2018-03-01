class AddEndedReasonToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :ended_reason, :integer
  end
end
