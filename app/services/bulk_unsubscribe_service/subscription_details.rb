module BulkUnsubscribeService
  class SubscriptionDetails

    def initialize(subscription, replacement)
      @subscription = subscription
      @replacement = replacement
    end

    def subscriber_list
      @_subscriber_list = @subscription.subscriber_list
    end

    def title
      subscriber_list.title
    end

    def links
      subscriber_list.links
    end

    def replacement_title
      @replacement.title
    end

    def replacement_url
      @replacement.url
    end

  end
end
