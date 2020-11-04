class UnsubscribeService < ApplicationService
  attr_reader :subscriber, :subscriptions, :reason

  def initialize(subscriber, subscriptions, reason, **)
    @subscriber = subscriber
    @subscriptions = subscriptions
    @reason = reason
  end

  def call
    ActiveRecord::Base.transaction do
      subscriptions.each do |subscription|
        subscription.end(reason: reason)
      end
    end
  end
end
