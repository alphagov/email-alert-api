class FindLatestMatchingSubscription
  def self.call(original_subscription)
    subscriber_list_id = original_subscription.subscriber_list_id
    subscriber_id = original_subscription.subscriber_id
    Subscription
      .where(subscriber_list_id:, subscriber_id:)
      .order("created_at DESC")
      .first
  end
end
