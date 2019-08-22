class SubscribersForImmediateEmailQuery
  def self.call
    unprocessed_subscription_content_exists =
      SubscriptionContent
        .joins(:subscription)
        .where(email_id: nil)
        .where("subscriptions.subscriber_id = subscribers.id")
        .arel
        .exists

    Subscriber.activated.where(unprocessed_subscription_content_exists)
  end
end
