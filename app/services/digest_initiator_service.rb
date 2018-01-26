class DigestInitiatorService
  def initialize(range:)
    @range = range
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    digest_run = nil

    run_with_advisory_lock do
      digest_run = DigestRun.find_or_initialize_by(
        date: Date.current, range: range
      )
      return if digest_run.persisted?
      digest_run.save!
    end

    #TODO think about this being retried
    #
    subscribers = DigestRunSubscriberQuery.call(digest_run: digest_run)

    digest_run_subscriber_params = subscribers.map do |subscriber|
      {
        subscriber_id: subscriber.id,
        digest_run_id: digest_run.id
      }
    end

    import_result = DigestRunSubscriber.import!(digest_run_subscriber_params)
    import_result.ids.each do |digest_run_subscriber_id|
      DigestEmailGenerationWorker.perform_async(digest_run_subscriber_id)
    end
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
