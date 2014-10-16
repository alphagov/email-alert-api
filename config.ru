require_relative "application"
require "http_api"
require "gov_delivery_client"

if ENV["RACK_ENV"] == "production"
  require "rack/logstasher"
  use(
    Rack::Logstasher::Logger,
    Logger.new("log/production.json.log"),
    extra_request_headers: {
      "GOVUK-Request-Id" => "govuk_request_id",
      "x-varnish" => "varnish_id"
    },
  )
end

APP = Application.new(
  config: CONFIG,
  gov_delivery_client: GovDeliveryClient.create_client(CONFIG.fetch(:gov_delivery)),
  storage_adapter: PostgresAdapter.new(config: CONFIG.fetch(:postgres)),
  uuid_generator: ->() { SecureRandom.uuid },
  clock: ->() { Time.now },
)

run HTTPAPI
