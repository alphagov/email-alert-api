class MakeDeliveryAttemptReferenceUuid < ActiveRecord::Migration[5.1]
  def up
    DeliveryAttempt.find_each do |delivery_attempt|
      delivery_attempt.update(reference: SecureRandom.uuid)
    end

    change_column :delivery_attempts, :reference, 'UUID USING reference::uuid'
  end

  def down
    change_column :delivery_attempts, :reference, :text
  end
end
