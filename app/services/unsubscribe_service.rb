module UnsubscribeService
  class << self
    def subscriber!(subscriber, reason)
      unsubscribe!(subscriber, subscriber.active_subscriptions, reason)
    end

    def subscription!(subscription, reason)
      unsubscribe!(subscription.subscriber, [subscription], reason)
    end

  private

    def unsubscribe!(subscriber, subscriptions, reason)
      ActiveRecord::Base.transaction do
        subscriptions.each do |subscription|
          subscription.end(reason: reason)
        end

        if !subscriber.deactivated? && no_other_subscriptions?(subscriber, subscriptions)
          subscriber.deactivate!
        end
      end
    end

    def no_other_subscriptions?(subscriber, subscriptions)
      (subscriber.subscriptions - subscriptions).empty?
    end
  end
end
