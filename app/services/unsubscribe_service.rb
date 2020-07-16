class UnsubscribeService
  attr_reader :subscriber, :subscriptions, :reason

  def self.call(*args)
    new(*args).call
  end

  def initialize(subscriber, subscriptions, reason)
    @subscriber = subscriber
    @subscriptions = subscriptions
    @reason = reason
  end

  private_class_method :new

  def call
    ActiveRecord::Base.transaction do
      subscriptions.each do |subscription|
        subscription.end(reason: reason)
      end

      if !subscriber.deactivated? && no_other_subscriptions?(subscriber, subscriptions)
        subscriber.deactivate!
      end
    end
  end

private

  def no_other_subscriptions?(subscriber, subscriptions)
    (subscriber.subscriptions - subscriptions).empty?
  end
end
