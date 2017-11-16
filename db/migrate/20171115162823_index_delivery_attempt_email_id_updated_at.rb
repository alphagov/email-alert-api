class IndexDeliveryAttemptEmailIdUpdatedAt < ActiveRecord::Migration[5.1]
  def change
    add_index :delivery_attempts, %i[email_id updated_at]
  end
end
