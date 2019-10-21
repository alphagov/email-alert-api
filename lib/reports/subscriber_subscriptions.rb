module Reports
  class SubscriberSubscriptions
    def initialize(email_addresses)
      @email_addresses = email_addresses
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      pp report
    end

  private

    attr_reader :email_addresses

    SUBSCRIBER_FIELDS = %i[address created_at updated_at deactivated_at].freeze
    SUBSCRIPTION_FIELDS = %i[created_at frequency source ended_at ended_reason].freeze
    SUBSCRIPTION_LIST_FIELDS = %i[title tags].freeze

    def report
      subscribers = Subscriber.where(address: email_addresses)

      subscribers.map do |subscriber|
        subscriber.as_json(
          only: SUBSCRIBER_FIELDS,
        ).merge(
          subscriptions: subscriber.subscriptions.map do |subscription|
            subscription.as_json(
              only: SUBSCRIPTION_FIELDS,
              include: [],
            ).merge(
              subscription.subscriber_list.as_json(
                only: SUBSCRIPTION_LIST_FIELDS,
              ),
            )
          end,
        )
      end
    end
  end
end
