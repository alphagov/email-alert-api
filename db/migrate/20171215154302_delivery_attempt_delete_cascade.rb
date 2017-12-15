class DeliveryAttemptDeleteCascade < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :delivery_attempts, :emails
    add_foreign_key :delivery_attempts, :emails, on_delete: :cascade
  end
end
