class DigestInitiatorService
  include Callable

  def initialize(date:, range:)
    @range = range
    @date = date
  end

  def call
    digest_run = DigestRun.find_or_create_by!(date:, range:)
    return if digest_run.processed_at

    create_digest_run_subscribers(digest_run)
    digest_run.update!(processed_at: Time.zone.now)
  end

private

  attr_reader :range, :date

  def create_digest_run_subscribers(digest_run)
    Metrics.digest_initiator_service(range) do
      subscriber_ids = DigestRunSubscriberQuery.call(digest_run:).pluck(:id)

      subscriber_ids.each_slice(1000) do |subscriber_ids_chunk|
        digest_run_subscriber_ids = DigestRunSubscriber.populate(digest_run, subscriber_ids_chunk)

        enqueue_jobs(digest_run_subscriber_ids)
      end
    end
  end

  def enqueue_jobs(digest_run_subscriber_ids)
    digest_run_subscriber_ids.each do |digest_run_subscriber_id|
      DigestEmailGenerationJob.perform_async(digest_run_subscriber_id)
    end
  end
end
