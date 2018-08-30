class SubscribersForImmediateEmailQuery
  def self.call
    new.call
  end

  def call
    subscriber_ids = Subscription.
        joins(:subscription_contents).
        where(subscription_contents: { email_id: nil }).
        select(:subscriber_id)
    Subscriber.activated.where(id: subscriber_ids)
  end
end
