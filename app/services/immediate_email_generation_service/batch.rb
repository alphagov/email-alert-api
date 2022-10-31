class ImmediateEmailGenerationService
  class Batch
    def initialize(content, subscription_ids)
      @content = content
      @subscription_ids = subscription_ids
    end

    def generate_emails
      email_ids = []
      return email_ids unless subscriptions_to_fulfill.any?

      ActiveRecord::Base.transaction do
        email_ids = ImmediateEmailBuilder.call(
          content_change || message,
          subscriptions_to_fulfill,
        )

        SubscriptionContent.populate_for_content(
          content,
          subscription_content_records(email_ids),
        )
      end

      Metrics.content_change_emails(content_change, email_ids.count) if content_change
      email_ids
    end

  private

    attr_reader :subscription_ids, :content

    def subscription_content_records(email_ids)
      subscriptions_to_fulfill.zip(email_ids).map do |subscription, email_id|
        { subscription_id: subscription.id, email_id: }
      end
    end

    def subscriptions_to_fulfill
      @subscriptions_to_fulfill ||= begin
        criteria = { message:,
                     content_change:,
                     subscription_id: subscription_ids }.compact
        covered_by_earlier_attempts = SubscriptionContent.where(criteria)
                                                         .pluck(:subscription_id)
        scope =
          if override_subscription_frequency_to_immediate
            Subscription
          else
            Subscription.immediately
          end
        scope.active
             .includes(:subscriber_list, :subscriber)
             .where(id: subscription_ids - covered_by_earlier_attempts)
      end
    end

    def content_change
      content if content.is_a?(ContentChange)
    end

    def message
      content if content.is_a?(Message)
    end

    def override_subscription_frequency_to_immediate
      if content.respond_to?(:override_subscription_frequency_to_immediate)
        content.override_subscription_frequency_to_immediate
      else
        false
      end
    end
  end
end
