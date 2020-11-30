GovukError.configure do |config|
  config.excluded_exceptions << "SendEmailService::NotifyCommunicationFailureError"
end
