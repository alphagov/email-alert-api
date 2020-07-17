class DigestInitiatorService < ApplicationService
  def initialize(range:)
    @range = range
  end

  def call
    digest_run = create_digest_run
    return if digest_run.nil?

    Metrics.digest_initiator_service(range) do
      subscriber_ids = DigestRunSubscriberQuery.call(digest_run: digest_run).pluck(:id)

      subscriber_ids.each_slice(1000) do |subscriber_ids_chunk|
        digest_run_subscriber_ids = DigestRunSubscriber.populate(digest_run, subscriber_ids_chunk)

        enqueue_jobs(digest_run_subscriber_ids)
      end

      digest_run.update(subscriber_count: subscriber_ids.count)
    end
  end

private

  attr_reader :range

  def create_digest_run
    run_with_advisory_lock do
      digest_run = DigestRun.find_or_initialize_by(
        date: Date.current, range: range,
      )
      return if digest_run.persisted?

      digest_run.save!
      digest_run
    end
  end

  def enqueue_jobs(digest_run_subscriber_ids)
    Array(digest_run_subscriber_ids).each do |digest_run_subscriber_id|
      DigestEmailGenerationWorker.perform_async(digest_run_subscriber_id)
    end
  end

  def run_with_advisory_lock
    DigestRun.with_advisory_lock(lock_name, timeout_seconds: 0) do
      yield
    end
  end

  def lock_name
    "#{range}_digest_initiator"
  end
end
