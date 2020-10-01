class ApplicationWorker
  include Sidekiq::Worker

private

  def run_with_advisory_lock(model, unique_ref)
    ApplicationRecord.with_advisory_lock("#{model}-#{unique_ref}", timeout_seconds: 0) { yield }
  end
end
