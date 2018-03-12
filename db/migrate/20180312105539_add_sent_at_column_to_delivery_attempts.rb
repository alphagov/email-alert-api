class AddSentAtColumnToDeliveryAttempts < ActiveRecord::Migration[5.1]
  def change
    add_column :delivery_attempts, :sent_at, :datetime
  end
end
