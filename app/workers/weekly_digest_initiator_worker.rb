class WeeklyDigestInitiatorWorker
  include Sidekiq::Worker

  sidekiq_retry_in do |count|
    60 * (count + 1)
  end

  sidekiq_options retry: 3

  def perform(date = Date.current.to_s)
    run_with_advisory_lock(date) do
      DigestInitiatorService.call(date: Date.parse(date), range: Frequency::WEEKLY)
    end
  end

  def run_with_advisory_lock(date)
    key = "#{Frequency::WEEKLY}_digest_initiator-#{date}"
    ApplicationRecord.with_advisory_lock(key, timeout_seconds: 0) { yield }
  end
end
