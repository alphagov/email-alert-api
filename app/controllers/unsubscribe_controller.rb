class UnsubscribeController < ApplicationController
  def unsubscribe
    UnsubscribeService.subscription!(subscription, :unsubscribed)
  end

  def unsubscribe_all
    UnsubscribeService.subscriber!(subscriber, :unsubscribed)
  end

private

  def subscription
    Subscription.active.find(id)
  end

  def subscriber
    Subscriber.activated.find(id)
  end

  def id
    params.fetch(:id)
  end
end
