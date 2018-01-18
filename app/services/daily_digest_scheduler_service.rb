class DailyDigestSchedulerService
  LOCK_NAME = "daily_digest_scheduler".freeze

  def self.call(*args)
    new.call(*args)
  end

  def call
    run_with_advisory_lock do
      digest_run = DigestRun.find_or_initialize_by(
        date: Date.current, range: DigestRun::DAILY
      )
      return if digest_run.persisted?
      digest_run.save!
    end

    #enqueue the digest creation workers TBC
  end

private

  def run_with_advisory_lock
    DigestRun.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      yield
    end
  end
end
