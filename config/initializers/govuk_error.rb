GovukError.configure do |config|
  config.excluded_exceptions << "DeliveryRequestWorker::ProviderCommunicationFailureError"
end
