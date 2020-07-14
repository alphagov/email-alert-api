class ImmediateEmailGenerationService
  class Batch
    def initialize(content, subscription_ids_by_subscriber_id)
      @content = content
      @subscription_ids_by_subscriber_id = subscription_ids_by_subscriber_id
    end

    def generate_emails
      email_ids = []
      return email_ids unless email_parameters.any?

      ActiveRecord::Base.transaction do
        email_ids = ContentChangeEmailBuilder.call(email_parameters) if content_change
        email_ids = MessageEmailBuilder.call(email_parameters) if message

        records = subscription_content_records(email_ids)
        SubscriptionContent.populate_for_content(content, records)
      end

      MetricsService.content_change_emails(content_change, email_parameters.count) if content_change
      email_ids
    end

  private

    attr_reader :subscription_ids_by_subscriber_id, :content

    def email_parameters
      @email_parameters ||= begin
        subscriptions_to_fulfill_by_subscriber.map do |(subscriber, subscriptions)|
          {
            address: subscriber.address,
            content_change: content_change,
            message: message,
            subscriptions: subscriptions,
            subscriber_id: subscriber.id,
          }.compact
        end
      end
    end

    def subscription_content_records(email_ids)
      email_parameters.flat_map.with_index do |params, index|
        params[:subscriptions].map do |subscription|
          { subscription_id: subscription.id, email_id: email_ids[index] }
        end
      end
    end

    def subscriptions_to_fulfill_by_subscriber
      all_subscribers = activated_subscribers(subscription_ids_by_subscriber_id.keys)
      all_subscriptions = unfulfilled_active_subscriptions(
        subscription_ids_by_subscriber_id.values.flatten,
      )

      subscription_ids_by_subscriber_id
        .each_with_object({}) do |(subscriber_id, subscription_ids), memo|
          subscriber = all_subscribers[subscriber_id]
          subscriptions = all_subscriptions.values_at(*subscription_ids).compact
          memo[subscriber] = subscriptions if subscriber && subscriptions.any?
        end
    end

    def activated_subscribers(subscriber_ids)
      Subscriber.activated
                .where(id: subscriber_ids)
                .index_by(&:id)
    end

    def unfulfilled_active_subscriptions(subscription_ids)
      criteria = { message: message,
                   content_change: content_change,
                   subscription_id: subscription_ids }.compact
      covered_by_earlier_attempts = SubscriptionContent.where(criteria)
                                                       .pluck(:subscription_id)
      Subscription.active
                  .immediately
                  .includes(:subscriber_list)
                  .where(id: subscription_ids - covered_by_earlier_attempts)
                  .index_by(&:id)
    end

    def content_change
      content if content.is_a?(ContentChange)
    end

    def message
      content if content.is_a?(Message)
    end
  end
end
