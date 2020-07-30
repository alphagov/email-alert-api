Sidekiq.configure_server do
  # Calls to Rails.logger in a sidekiq process will use Sidekiq's logger
  Rails.logger = Sidekiq::Logging.logger
end
