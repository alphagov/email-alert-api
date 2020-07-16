class UnsubscribeController < ApplicationController
  def unsubscribe
    subscription = Subscription.active.find(id)
    UnsubscribeService.unsubscribe!(subscription.subscriber, [subscription], :unsubscribed)
  end

  def unsubscribe_all
    subscriber = Subscriber.activated.find(id)
    UnsubscribeService.unsubscribe!(subscriber, subscriber.active_subscriptions, :unsubscribed)
  end

private

  def id
    params.fetch(:id)
  end
end
