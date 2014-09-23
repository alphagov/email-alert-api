class CreateTopic
  def initialize(topic_attributes:, gov_delivery_client:, context:)
    @topic_attributes = topic_attributes
    @gov_delivery_client = gov_delivery_client
    @context = context
  end

  def call
    context.success(
      subscription_url: subscription_url,
    )
  end

private

  attr_reader :topic_attributes, :gov_delivery_client, :context

  def subscription_url
    subscription_url_template % { topic_id: topic_id }
  end

  def subscription_url_template
    GOVDELIVERY_CREDENTIALS.fetch(:signup_form)
  end

  def topic_id
    @topic_id ||= gov_delivery_client.create_topic(name: topic_name).id
  end

  def topic_name
    topic_attributes.fetch("title")
  end
end
