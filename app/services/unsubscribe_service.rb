module UnsubscribeService
  class << self
    def subscriber!(subscriber, reason)
      ActiveRecord::Base.transaction do
        unsubscribe_subscriptions!(subscriber.active_subscriptions, reason)
        unsubscribe_subscriber!(subscriber)
      end
    end

    def subscription!(subscription, reason)
      ActiveRecord::Base.transaction do
        unsubscribe_subscriptions!([subscription], reason)
        unsubscribe_subscriber!(subscription.subscriber)
      end
    end

    def spam_report!(delivery_attempt)
      subscriber_id = delivery_attempt.email.subscriber_id
      subscriber = Subscriber.find(subscriber_id)
      ActiveRecord::Base.transaction do
        unsubscribe_subscriptions!(subscriber.active_subscriptions, :marked_as_spam, delivery_attempt.email)
        unsubscribe_subscriber!(subscriber)
      end
    end

    def subscriber_list!(list, reason)
      ActiveRecord::Base.transaction do
        subscriptions = list.subscriptions.active
        unsubscribe_subscriptions!(subscriptions, reason)
        Subscriber.where(subscriptions: subscriptions).each do |subscriber|
          unsubscribe_subscriber!(subscriber)
        end
      end
    end

  private

    def unsubscribe_subscriptions!(subscriptions, reason, email = nil)
      subscriptions.each do |subscription|
        subscription.end(reason: reason)
      end

      email.update!(marked_as_spam: true) if email && reason == :marked_as_spam
    end

    def unsubscribe_subscriber!(subscriber)
      if !subscriber.deactivated? && subscriber.reload.active_subscriptions.empty?
        subscriber.deactivate!
      end
    end
  end
end
