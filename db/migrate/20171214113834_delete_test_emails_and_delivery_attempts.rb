class DeleteTestEmailsAndDeliveryAttempts < ActiveRecord::Migration[5.1]
  def up
    # Emails and DeliveryAttempts at this point are all test data
    DeliveryAttempt.destroy_all
    Email.destroy_all
  end
end
