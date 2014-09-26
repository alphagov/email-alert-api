class CreateTopic
  def initialize(topic_attributes:, gov_delivery_client:, topic_builder:, context:)
    @topic_attributes = topic_attributes
    @gov_delivery_client = gov_delivery_client
    @topic_builder = topic_builder
    @context = context
  end

  def call
    context.created(topic: new_topic)
  end

private

  attr_reader(
    :topic_attributes,
    :topic_builder,
    :gov_delivery_client,
    :context,
  )

  def new_topic
    topic_builder.call(topic_data)
  end

  def topic_data
    {
      gov_delivery_id: remote_topic_data.id,
      subscription_url: remote_topic_data.link,
    }.merge(topic_attributes)
  end

  def remote_topic_data
    @remote_topic_data ||= gov_delivery_client.create_topic(name: topic_name)
  end

  def topic_name
    topic_attributes.fetch("title")
  end
end
