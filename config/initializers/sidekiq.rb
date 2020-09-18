Sidekiq.configure_server do |config|
  # Calls to Rails.logger in a sidekiq process will use Sidekiq's logger
  Rails.logger = Sidekiq::Logging.logger

  config.death_handlers << lambda { |job, _error|
    digest = job["unique_digest"]
    SidekiqUniqueJobs::Digests.delete_by_digest(digest) if digest
  }
end
