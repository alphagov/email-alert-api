require_relative "configuration"
require "core_ext"
require "create_topic"

class Application
  def initialize(gov_delivery_client: default_gov_delivery_client)
    @gov_delivery_client = gov_delivery_client
  end

  def create_topic(context)
    CreateTopic.new(
      topic_attributes: context.params.slice("title", "tags"),
      gov_delivery_client: gov_delivery_client,
      context: context,
    ).call
  end

  private

  attr_reader :gov_delivery_client

  def default_gov_delivery_client
    GovDeliveryClient.create_client(GOVDELIVERY_CREDENTIALS)
  end
end
