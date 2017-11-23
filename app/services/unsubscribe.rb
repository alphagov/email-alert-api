module Unsubscribe
  class << self
    def subscriber!(subscriber)
      destroy_subscriptions!(subscriber.subscriptions)
      nullify_email_address!(subscriber)
    end

    def subscription!(subscription)
      destroy_subscriptions!(subscription)

      if last_subscription?(subscription)
        nullify_email_address!(subscription.subscriber)
      end
    end

  private

    def nullify_email_address!(subscriber)
      subscriber.update!(address: nil)
    end

    def destroy_subscriptions!(subscriptions)
      Array(subscriptions).each(&:destroy)
    end

    def last_subscription?(subscription)
      subscriber = subscription.subscriber
      (subscriber.subscriptions - [subscription]).empty?
    end
  end
end
