module UnsubscribeService
  class << self
    def subscriber!(subscriber)
      unsubscribe!(subscriber, subscriber.subscriptions)
    end

    def subscription!(subscription)
      unsubscribe!(subscription.subscriber, [subscription])
    end

  private

    def unsubscribe!(subscriber, subscriptions)
      ActiveRecord::Base.transaction do
        nullify_references_to_subscriptions!(subscriptions)

        subscriptions.each(&:destroy)

        if no_other_subscriptions?(subscriber, subscriptions)
          subscriber.nullify_address!
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
