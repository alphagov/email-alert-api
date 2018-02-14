class SubscribersForImmediateEmailQuery
  def self.call
    Subscriber
      .where(
        unprocessed_subscription_contents_exist_for_subscribers
       )
       .where.not(address: nil)
  end

  def self.unprocessed_subscription_contents_exist_for_subscribers
    SubscriptionContent
      .joins(:subscription)
      .where(email_id: nil)
      .where("subscriptions.subscriber_id = subscribers.id")
      .exists
  end
end
