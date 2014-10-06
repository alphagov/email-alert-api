class CreateSubscriberList
  def initialize(gov_delivery_client:, subscription_link_template:, subscriber_list_builder:, subscriber_list_attributes:, context:)
    @gov_delivery_client = gov_delivery_client
    @subscription_link_template = subscription_link_template
    @subscriber_list_builder = subscriber_list_builder
    @subscriber_list_attributes = subscriber_list_attributes
    @context = context
  end

  def call
    context.created(subscriber_list: new_subscriber_list)
  end

private

  attr_reader(
    :subscription_link_template,
    :gov_delivery_client,
    :subscriber_list_builder,
    :subscriber_list_attributes,
    :context,
  )

  def new_subscriber_list
    subscriber_list_builder.call(subscriber_list_data)
  end

  def subscriber_list_data
    {
      "gov_delivery_id" => gov_delivery_id,
      "subscription_url" => subscription_url,
    }.merge(subscriber_list_attributes)
  end

  def remote_subscriber_list_data
    @remote_subscriber_list_data ||= gov_delivery_client.create_topic(name: subscriber_list_name)
  end

  def subscriber_list_name
    subscriber_list_attributes.fetch("title")
  end

  def gov_delivery_id
    remote_subscriber_list_data.to_param
  end

  def subscription_url
    subscription_link_template % { topic_id: gov_delivery_id }
  end
end
