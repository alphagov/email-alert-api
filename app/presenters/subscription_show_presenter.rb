class SubscriptionShowPresenter
  def self.call(subscription)
    new.call(subscription)
  end

  def call(subscription)
    {
      id: subscription.id,
      frequency: subscription.frequency,
      source: subscription.source,
      ended: subscription.ended?,
      ended_at: subscription.ended_at,
      ended_reason: subscription.ended_reason,
      created_at: subscription.created_at,
      updated_at: subscription.updated_at,
      subscriber_list: subscription.subscriber_list.as_json,
      subscriber: subscription.subscriber.as_json,
    }
  end
end
