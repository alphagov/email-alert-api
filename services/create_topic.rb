class CreateTopic
  def initialize(gov_delivery_client:, subscription_link_template:, topic_builder:, topic_attributes:, context:)
    @gov_delivery_client = gov_delivery_client
    @subscription_link_template = subscription_link_template
    @topic_builder = topic_builder
    @topic_attributes = topic_attributes
    @context = context
  end

  def call
    context.created(topic: new_topic)
  end

private

  attr_reader(
    :subscription_link_template,
    :gov_delivery_client,
    :topic_builder,
    :topic_attributes,
    :context,
  )

  def new_topic
    topic_builder.call(topic_data)
  end

  def topic_data
    {
      gov_delivery_id: gov_delivery_id,
      subscription_url: subscription_url,
    }.merge(topic_attributes)
  end

  def remote_topic_data
    @remote_topic_data ||= gov_delivery_client.create_topic(name: topic_name)
  end

  def topic_name
    topic_attributes.fetch("title")
  end

  def gov_delivery_id
    remote_topic_data.to_param
  end

  def subscription_url
    subscription_link_template % { topic_id: gov_delivery_id }
  end
end
