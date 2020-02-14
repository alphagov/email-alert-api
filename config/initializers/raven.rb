Raven.configure do |config|
  config.excluded_exceptions += %w(
    RatelimitExceededError
  )

  config.rails_report_rescued_exceptions = false
end
