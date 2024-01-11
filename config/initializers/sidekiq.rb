# Set strict args so we're ready for Sidekiq 7
Sidekiq.strict_args!

Sidekiq.configure_server do |config|
  config.logger.level = Rails.logger.level
end
