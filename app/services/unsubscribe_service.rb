module UnsubscribeService
  class << self
    def subscriber!(subscriber, reason)
      unsubscribe!(subscriber, subscriber.active_subscriptions, reason)
    end

    def subscription!(subscription, reason)
      unsubscribe!(subscription.subscriber, [subscription], reason)
    end

    def subscriptions!(subscriber, subscriptions, reason, ended_email_id: nil)
      subscription_subscriber_ids = subscriptions.map(&:subscriber_id).uniq
      raise "Can't process subscriptions for multiple subscribers" unless subscription_subscriber_ids.length == 1
      raise "Subscriptions don't match subscriber" unless subscription_subscriber_ids.first == subscriber.id

      unsubscribe!(
        subscriber,
        subscriptions,
        reason,
        ended_email_id: ended_email_id
      )
    end

    def spam_report!(delivery_attempt)
      subscriber_id = delivery_attempt.email.subscriber_id
      subscriber = Subscriber.find(subscriber_id)
      unsubscribe!(
        subscriber,
        subscriber.active_subscriptions,
        :marked_as_spam,
        email_marked_as_spam: delivery_attempt.email
      )
    end

  private

    def unsubscribe!(
      subscriber,
          subscriptions,
          reason,
          email_marked_as_spam: nil,
          ended_email_id: nil
        )
      ActiveRecord::Base.transaction do
        subscriptions.each do |subscription|
          subscription.end(reason: reason, ended_email_id: ended_email_id)
        end

        email_marked_as_spam.update!(marked_as_spam: true) if email_marked_as_spam && reason == :marked_as_spam

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
