class ImmediateEmailGenerationService
  class Batch
    def initialize(content, subscription_ids)
      @content = content
      @subscription_ids = subscription_ids
    end

    def generate_emails
      email_ids = []
      return email_ids unless email_parameters.any?

      ActiveRecord::Base.transaction do
        email_ids = ImmediateEmailBuilder.call(email_parameters)
        records = subscription_content_records(email_ids)
        SubscriptionContent.populate_for_content(content, records)
      end

      Metrics.content_change_emails(content_change, email_parameters.count) if content_change
      email_ids
    end

  private

    attr_reader :subscription_ids, :content

    def email_parameters
      @email_parameters ||= begin
        subscriptions_to_fulfill.map do |subscription|
          {
            content: content_change || message,
            subscription: subscription,
          }.compact
        end
      end
    end

    def subscription_content_records(email_ids)
      email_parameters.flat_map.with_index do |params, index|
        { subscription_id: params[:subscription].id, email_id: email_ids[index] }
      end
    end

    def subscriptions_to_fulfill
      criteria = { message: message,
                   content_change: content_change,
                   subscription_id: subscription_ids }.compact
      covered_by_earlier_attempts = SubscriptionContent.where(criteria)
                                                       .pluck(:subscription_id)
      Subscription.active
                  .immediately
                  .includes(:subscriber_list, :subscriber)
                  .where(id: subscription_ids - covered_by_earlier_attempts)
    end

    def content_change
      content if content.is_a?(ContentChange)
    end

    def message
      content if content.is_a?(Message)
    end
  end
end
