require "cucumber"
require "rack/test"

require "pry"
require "awesome_print"

require_relative "../../application"

$LOAD_PATH.push(ROOT.join("features/support"))

# Put together an application instace with mock things

require "mock_gov_delivery_client"
require "deterministic_uuid_generator"

UUID_GENERATOR = DeterministicUUIDGenerator.new
GOV_DELIVERY_API_CLIENT = MockGovDeliveryClient.new

STORAGE_ADAPTER = PostgresAdapter.new(
  config: CONFIG.fetch(:postgres),
)

APP = Application.new(
  config: CONFIG,
  uuid_generator: UUID_GENERATOR,
  storage_adapter: STORAGE_ADAPTER,
  gov_delivery_client: GOV_DELIVERY_API_CLIENT,
)

# Sinatra stuff

require "http_api"
module SinatraTestIntegration
  include Rack::Test::Methods

  def app
    HTTPAPI.new
  end
end

# Reset mocks between tests

After do
  GOV_DELIVERY_API_CLIENT.reset!
  UUID_GENERATOR.reset!
  STORAGE_ADAPTER.clear
end

# Helpers and other support etc

require "bare_app_integration_helpers"
require "subscriber_list_helpers"

World(SinatraTestIntegration)
World(BareAppIntegrationHelpers)
World(SubscriberListHelpers)
