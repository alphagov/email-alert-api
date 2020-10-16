GovukError.configure do |config|
  config.excluded_exceptions << "DeliveryRequestService::ProviderCommunicationFailureError"
end
