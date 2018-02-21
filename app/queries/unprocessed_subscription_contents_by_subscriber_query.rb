class UnprocessedSubscriptionContentsBySubscriberQuery
  attr_reader :subscriber_ids

  def self.call(*args)
    new(*args).call
  end

  def initialize(subscriber_ids)
    @subscriber_ids = subscriber_ids
  end

  def call
    from_query = <<-SQL
      (
        select subscription_contents.*, subscriptions.subscriber_id AS subscriber_id
        from subscription_contents
        join subscriptions on subscription_contents.subscription_id = subscriptions.id
      ) as subscription_contents
    SQL

    subscription_contents = SubscriptionContent
      .from(from_query)
      .includes(:subscription)
      .where(email_id: nil)

    transform_results(subscription_contents)
  end

  private_class_method :new

private

  def transform_results(subscription_contents)
    subscription_contents.each_with_object({}) do |subscription_content, results|
      current_value = results[subscription_content.subscriber_id] || {}
      subscription_contents_for_content_change = Array(current_value[subscription_content.content_change_id])
      subscription_contents_for_content_change << subscription_content

      results[subscription_content.subscriber_id] = current_value.merge(
        subscription_content.content_change_id => subscription_contents_for_content_change
      )
    end
  end
end
