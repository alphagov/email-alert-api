class AddCompletedAtColumnToDeliveryAttempt < ActiveRecord::Migration[5.1]
  def change
    add_column :delivery_attempts, :completed_at, :datetime
  end
end
