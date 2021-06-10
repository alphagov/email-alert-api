GovukError.configure do |config|
  config.excluded_exceptions += %w[
    SendEmailService::NotifyCommunicationFailure
    RatelimitExceededError
  ]

  config.rails.report_rescued_exceptions = false
end
