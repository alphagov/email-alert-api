class SubscriptionsForSubscriptionContentQuery
  def self.call(filter_name, content_change_or_message)
    raise ArgumentError.new("Filter must be either :for_content_change or :for_message") unless %i(for_content_change for_message).include?(filter_name)

    Subscription
        .send(filter_name, content_change_or_message)
        .active
        .immediately
        .subscription_ids_by_subscriber
        .values
        .flatten
  end
end
