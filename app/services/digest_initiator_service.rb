class DigestInitiatorService < ApplicationService
  def initialize(date:, range:)
    @range = range
    @date = date
  end

  def call
    run_with_advisory_lock do
      digest_run = DigestRun.find_or_create_by!(date: date, range: range)
      return if digest_run.processed_at

      create_digest_run_subscribers(digest_run)
      digest_run.update!(processed_at: Time.zone.now)
    end
  end

private

  attr_reader :range, :date

  def create_digest_run_subscribers(digest_run)
    Metrics.digest_initiator_service(range) do
      subscriber_ids = DigestRunSubscriberQuery.call(digest_run: digest_run).pluck(:id)

      subscriber_ids.each_slice(1000) do |subscriber_ids_chunk|
        digest_run_subscriber_ids = DigestRunSubscriber.populate(digest_run, subscriber_ids_chunk)

        enqueue_jobs(digest_run_subscriber_ids)
      end
    end
  end

  def enqueue_jobs(digest_run_subscriber_ids)
    digest_run_subscriber_ids.each do |digest_run_subscriber_id|
      DigestEmailGenerationWorker.perform_async(digest_run_subscriber_id)
    end
  end

  def run_with_advisory_lock
    DigestRun.with_advisory_lock("#{range}_digest_initiator-#{date}", timeout_seconds: 0) do
      yield
    end
  end
end
