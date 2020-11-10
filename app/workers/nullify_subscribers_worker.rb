class NullifySubscribersWorker < ApplicationWorker
  def perform
    run_with_advisory_lock(Subscriber, "nullify") do
      nullifyable_subscribers.update_all(address: nil)
    end
  end

private

  def nullifyable_subscribers
    recently_active_subscriptions = Subscription
      .where("subscriptions.subscriber_id = subscribers.id")
      .where("ended_at IS NULL OR ended_at > ?", nullifyable_period)
      .arel.exists

    Subscriber
      .not_nullified
      .where("created_at < ?", nullifyable_period)
      .where.not(recently_active_subscriptions)
  end

  def nullifyable_period
    @nullifyable_period ||= 28.days.ago
  end
end
