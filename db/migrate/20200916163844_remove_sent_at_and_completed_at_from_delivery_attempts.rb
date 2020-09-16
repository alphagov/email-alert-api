class RemoveSentAtAndCompletedAtFromDeliveryAttempts < ActiveRecord::Migration[6.0]
  def up
    change_table :delivery_attempts, bulk: true do |t|
      t.remove :sent_at, :completed_at
    end
  end

  def down
    change_table :delivery_attempts, bulk: true do |t|
      t.column :sent_at, :datetime
      t.column :completed_at, :datetime
    end
  end
end
