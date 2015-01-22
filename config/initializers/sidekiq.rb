Sidekiq.configure_server do |config|
  config.redis = EmailAlertAPI.config.redis_config
  config.error_handlers << Proc.new {|ex, context_hash| Airbrake.notify(ex, context_hash) }
end

Sidekiq.configure_client do |config|
  config.redis = EmailAlertAPI.config.redis_config
end

require 'sidekiq/logging/json'
Sidekiq.logger.formatter = Sidekiq::Logging::Json::Logger.new
