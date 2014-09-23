require "cucumber"
require "rack/test"
require "ostruct"

require "pry"
require "awesome_print"

require_relative "../../application"

class MockGovDeliveryClient
  def initialize
    reset!
  end

  def created_topics
    @topics
  end

  def reset!
    @topics = {}
  end

  def create_topic(attributes)
    topic_id = generate_topic_id

    @topics[topic_id] = attributes

    OpenStruct.new(
      id: topic_id,
      link: "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=ABC_1234",
    )
  end

  def generate_topic_id
    "ABC_1234"
  end
end

GOV_DELIVERY_API_CLIENT = MockGovDeliveryClient.new
APP = Application.new(
  gov_delivery_client: GOV_DELIVERY_API_CLIENT,
)

After do
  GOV_DELIVERY_API_CLIENT.reset!
end

# Sinatra stuff

require "http_api"
module SinatraTestIntegration
  include Rack::Test::Methods

  def app
    HTTPAPI.new
  end
end

World(SinatraTestIntegration)
