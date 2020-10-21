class UnsubscribeService < ApplicationService
  attr_reader :subscriber, :subscriptions, :reason

  def initialize(subscriber, subscriptions, reason)
    @subscriber = subscriber
    @subscriptions = subscriptions
    @reason = reason
  end

  def call
    ActiveRecord::Base.transaction do
      subscriptions.each do |subscription|
        subscription.end(reason: reason)
      end

      if !subscriber.deactivated? && no_other_subscriptions?(subscriber, subscriptions)
        subscriber.deactivate
      end
    end
  end

private

  def no_other_subscriptions?(subscriber, subscriptions)
    (subscriber.subscriptions - subscriptions).empty?
  end
end
