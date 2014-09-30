require_relative "application"
require "http_api"
require "gov_delivery_client"

APP = Application.new(
  config: CONFIG,
  gov_delivery_client: GovDeliveryClient.create_client(CONFIG.fetch(:gov_delivery)),
  storage_adapter: PostgresAdapter.new(config: CONFIG.fetch(:postgres)),
)

run HTTPAPI
