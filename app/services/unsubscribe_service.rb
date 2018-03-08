module UnsubscribeService
  class << self
    def subscriber!(subscriber, reason)
      unsubscribe!(subscriber, subscriber.subscriptions, reason)
    end

    def subscription!(subscription, reason)
      unsubscribe!(subscription.subscriber, [subscription], reason)
    end

  private

    def unsubscribe!(subscriber, subscriptions, reason)
      ActiveRecord::Base.transaction do
        nullify_references_to_subscriptions!(subscriptions)

        subscriptions.each do |subscription|
          subscription.end(reason: reason)
        end

        if !subscriber.deactivated? && no_other_subscriptions?(subscriber, subscriptions)
          subscriber.deactivate!
        end
      end
    end

    def nullify_references_to_subscriptions!(subscriptions)
      SubscriptionContent
        .where(subscription: subscriptions)
        .update_all(subscription_id: nil)
    end

    def no_other_subscriptions?(subscriber, subscriptions)
      (subscriber.subscriptions - subscriptions).empty?
    end
  end
end
