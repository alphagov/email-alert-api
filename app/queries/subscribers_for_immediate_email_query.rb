class SubscribersForImmediateEmailQuery
  def self.call(content_change_id: nil, message_id: nil)
    additional_parameters = {
      content_change_id: content_change_id,
      message_id: message_id,
    }.compact

    unprocessed_subscription_content_exists =
      SubscriptionContent
        .joins(:subscription)
        .where({ email_id: nil }.merge(additional_parameters))
        .where("subscriptions.subscriber_id = subscribers.id")
        .arel
        .exists

    Subscriber.activated.where(unprocessed_subscription_content_exists)
  end
end
