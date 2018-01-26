class DigestInitiatorService
  def initialize(range:)
    @range = range
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    run_with_advisory_lock do
      digest_run = DigestRun.find_or_initialize_by(
        date: Date.current, range: range
      )
      return if digest_run.persisted?
      digest_run.save!
    end

    #enqueue the digest creation workers TBC
  end

private

  attr_reader :range

  def run_with_advisory_lock
    DigestRun.with_advisory_lock(lock_name, timeout_seconds: 0) do
      yield
    end
  end

  def lock_name
    "#{range}_digest_initiator"
  end
end
