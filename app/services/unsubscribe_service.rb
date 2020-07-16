module UnsubscribeService
  class << self
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
