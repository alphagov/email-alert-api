class UnsubscribeController < ApplicationController
  def unsubscribe
    subscription = Subscription.active.find(id)
    subscription.end(reason: :unsubscribed)
  end

  def unsubscribe_all
    subscriber = Subscriber.activated.find(id)
    UnsubscribeAllService.call(subscriber, :unsubscribed)
  end

private

  def id
    params.fetch(:id)
  end
end
