class UnprocessedSubscriptionContentsBySubscriberQuery
  attr_reader :subscriber_ids

  def self.call(*args)
    new(*args).call
  end

  def initialize(subscriber_ids)
    @subscriber_ids = subscriber_ids
  end

  def call
    transform_results(subscription_contents)
  end

  private_class_method :new

private

  def subscription_contents
    SubscriptionContent
      .joins(:subscription)
      .includes(:subscription)
      .where(email_id: nil, subscriptions: { subscriber_id: subscriber_ids })
  end

  def transform_results(subscription_contents)
    subscription_contents.each_with_object({}) do |subscription_content, results|
      subscriber_id = subscription_content.subscription.subscriber_id
      current_value = results[subscriber_id] || {}
      subscription_contents_for_content_change = Array(current_value[subscription_content.content_change_id])
      subscription_contents_for_content_change << subscription_content

      results[subscriber_id] = current_value.merge(
        subscription_content.content_change_id => subscription_contents_for_content_change
      )
    end
  end
end
