class UnsubscribeAllService < ApplicationService
  attr_reader :subscriber, :reason

  def initialize(subscriber, reason, **)
    @subscriber = subscriber
    @reason = reason
  end

  def call
    ended_count = subscriber.active_subscriptions
                            .update_all(ended_at: Time.zone.now,
                                        ended_reason: reason)

    Metrics.unsubscribed(reason, ended_count)
  end
end
