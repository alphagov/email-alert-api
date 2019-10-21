class SubscribersForImmediateEmailQuery
  def self.call(content_change_id: nil, message_id: nil)
    raise ArgumentError("Must specify either content_change_id or message_id") unless content_change_id || message_id

    unprocessed_subscription_content_exists =
      SubscriptionContent
        .joins(:subscription)
        .where(email_id: nil, content_change_id: content_change_id, message_id: message_id)
        .where("subscriptions.subscriber_id = subscribers.id")
        .arel
        .exists

    Subscriber.activated.where(unprocessed_subscription_content_exists)
  end
end
