class AddDefaultValueForDeliveryAttemptsStatus < ActiveRecord::Migration[5.1]
  def change
    change_column :delivery_attempts, :status, :integer, default: 0
  end
end
