require "cucumber"
require "rack/test"
require "ostruct"

require "pry"
require "awesome_print"

require_relative "../../application"

class MockGovDeliveryClient
  def initialize
    reset!
    @id_start = 1234
    @insert_count = 0
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
    @insert_count += 1

    OpenStruct.new(
      id: topic_id,
      link: "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=#{topic_id}",
    )
  end

  def generate_topic_id
    [
      "UKGOVUK",
      next_id,
    ].join("_")
  end

  def next_id
    @id_start + @insert_count
  end
end

GOV_DELIVERY_API_CLIENT = MockGovDeliveryClient.new

STORAGE_ADAPTER = PostgresAdapter.new(
  config: CONFIG.fetch(:postgres),
)

APP = Application.new(
  config: CONFIG,
  storage_adapter: STORAGE_ADAPTER,
  gov_delivery_client: GOV_DELIVERY_API_CLIENT,
)

After do
  GOV_DELIVERY_API_CLIENT.reset!
  STORAGE_ADAPTER.clear
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
