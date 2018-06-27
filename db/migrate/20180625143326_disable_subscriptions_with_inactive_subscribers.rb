class DisableSubscriptionsWithInactiveSubscribers < ActiveRecord::Migration[5.2]
  def up
    subscriptions = Subscription.active.where(subscriber: Subscriber.deactivated)
    subscriptions.find_each do |subscription|
      subscription.end(reason: :unsubscribed)
    end
  end
end
