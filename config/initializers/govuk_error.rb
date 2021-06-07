GovukError.configure do |config|
  config.excluded_exceptions += %w[
    SendEmailService::NotifyCommunicationFailure
    RatelimitExceededError
  ]
end
