class DeleteTestEmailsAndDeliveryAttempts < ActiveRecord::Migration[5.1]
  def up
    # Emails and DeliveryAttempts at this point are all test data
    Email.destroy_all
    DeliveryAttempt.destroy_all
  end
end
