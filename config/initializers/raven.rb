Raven.configure do |config|
  config.excluded_exceptions += %w(
    RatelimitExceededError
  )
end
