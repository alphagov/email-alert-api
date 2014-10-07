class CreateSubscriberList
  def initialize(gov_delivery_client:, subscription_link_template:, subscriber_list_builder:, responder:, title:, tags:)
    @gov_delivery_client = gov_delivery_client
    @subscription_link_template = subscription_link_template
    @subscriber_list_builder = subscriber_list_builder
    @responder = responder
    @title = title
    @tags = tags
  end

  def call
    responder.created(subscriber_list: new_subscriber_list)
  end

private

  attr_reader(
    :subscription_link_template,
    :gov_delivery_client,
    :subscriber_list_builder,
    :responder,
    :title,
    :tags,
  )

  def new_subscriber_list
    subscriber_list_builder.call(subscriber_list_data)
  end

  def subscriber_list_data
    {
      gov_delivery_id: gov_delivery_id,
      subscription_url: subscription_url,
      title: title,
      tags: tags.to_h,
    }
  end

  def remote_subscriber_list_data
    @remote_subscriber_list_data ||= gov_delivery_client.create_topic(name: title)
  end

  def gov_delivery_id
    remote_subscriber_list_data.to_param
  end

  def subscription_url
    subscription_link_template % { topic_id: gov_delivery_id }
  end
end
