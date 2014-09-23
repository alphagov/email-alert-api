class CreateTopic
  def initialize(topic_attributes:, gov_delivery_client:, context:)
    @topic_attributes = topic_attributes
    @gov_delivery_client = gov_delivery_client
    @context = context
  end

  def call
    context.created(
      subscription_url: topic_link,
    )
  end

private

  attr_reader :topic_attributes, :gov_delivery_client, :context

  def topic_link
    topic.link
  end

  def topic
    @topic ||= gov_delivery_client.create_topic(name: topic_name)
  end

  def topic_name
    topic_attributes.fetch("title")
  end
end
