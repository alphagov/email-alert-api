module UnsubscribeService
  class << self
    def subscriber!(subscriber, reason)
      unsubscribe!(subscriber, subscriber.active_subscriptions, reason)
    end

    def subscription!(subscription, reason)
      unsubscribe!(subscription.subscriber, [subscription], reason)
    end

    def spam_report!(delivery_attempt)
      subscriber_id = delivery_attempt.email.subscriber_id
      subscriber = Subscriber.find(subscriber_id)
      unsubscribe!(subscriber, subscriber.active_subscriptions, :marked_as_spam, delivery_attempt.email)
    end

  private

    def unsubscribe!(subscriber, subscriptions, reason, email = nil)
      ActiveRecord::Base.transaction do
        subscriptions.each do |subscription|
          subscription.end(reason: reason)
        end

        email.update!(marked_as_spam: true) if email && reason == :marked_as_spam

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
