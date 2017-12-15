class DeleteTestEmailsAndDeliveryAttempts < ActiveRecord::Migration[5.1]
  def up
    # Emails, DeliveryAttempts and SubscriptionContents at this point are all test data
    SubscriptionContent.delete_all
    DeliveryAttempt.delete_all
    Email.delete_all
  end
end
