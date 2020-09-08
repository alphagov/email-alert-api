class UnsubscribeAllService < ApplicationService
  attr_reader :subscriber, :reason

  def initialize(subscriber, reason, **)
    @subscriber = subscriber
    @reason = reason
  end

  def call
    UnsubscribeService.call(subscriber, subscriber.active_subscriptions, reason)
  end
end
