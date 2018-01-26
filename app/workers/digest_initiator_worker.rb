class DigestInitiatorWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  sidekiq_retry_in do |count|
    60 * (count + 1)
  end
end
