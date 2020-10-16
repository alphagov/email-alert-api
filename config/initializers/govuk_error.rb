GovukError.configure do |config|
  config.excluded_exceptions << "SendEmailService::ProviderCommunicationFailureError"
end
