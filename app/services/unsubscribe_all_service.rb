class UnsubscribeAllService
  include Callable

  attr_reader :subscriber, :reason

  def initialize(subscriber, reason, **)
    @subscriber = subscriber
    @reason = reason
  end

  def call
    ended_time = Time.zone.now
    ended_count = subscriber.active_subscriptions
                            .update_all(ended_at: ended_time,
                                        updated_at: ended_time,
                                        ended_reason: reason)

    Metrics.unsubscribed(reason, ended_count)
  end
end
