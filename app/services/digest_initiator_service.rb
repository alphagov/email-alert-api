module DigestInitiatorService
  extend ActiveSupport::Concern

  class_methods do
    def call(*args)
      new.call(*args)
    end
  end

  def call
    run_with_advisory_lock do
      digest_run = DigestRun.find_or_initialize_by(
        date: Date.current, range: self.class::RANGE
      )
      return if digest_run.persisted?
      digest_run.save!
    end

    #enqueue the digest creation workers TBC
  end

private

  def run_with_advisory_lock
    DigestRun.with_advisory_lock(self.class::LOCK_NAME, timeout_seconds: 0) do
      yield
    end
  end
end
