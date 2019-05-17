class FindLatestMatchingSubscription
  def self.call(original_subscription)
    subscriber_list_id = original_subscription.subscriber_list_id
    subscriber_id = original_subscription.subscriber_id
    frequency = original_subscription.frequency
    Subscription.
      where(subscriber_list_id: subscriber_list_id, subscriber_id: subscriber_id, frequency: frequency).
      order("created_at DESC")
      .first
  end
end
