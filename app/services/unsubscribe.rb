module Unsubscribe
  class << self
    def subscriber!(subscriber)
      unsubscribe!(subscriber, subscriber.subscriptions)
    end

    def subscription!(subscription)
      unsubscribe!(subscription.subscriber, [subscription])
    end

  private

    def unsubscribe!(subscriber, subscriptions)
      subscriptions.each(&:destroy)

      if no_other_subscriptions?(subscriber, subscriptions)
        subscriber.update!(address: nil)
      end
    end

    def no_other_subscriptions?(subscriber, subscriptions)
      (subscriber.subscriptions - subscriptions).empty?
    end
  end
end
