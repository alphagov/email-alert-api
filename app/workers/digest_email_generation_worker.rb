class DigestEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_digest

  def perform(digest_run_subscriber_id)
    @digest_run_subscriber = DigestRunSubscriber.includes(:subscriber, :digest_run).find(digest_run_subscriber_id)
    @subscriber = digest_run_subscriber.subscriber
    @digest_run = digest_run_subscriber.digest_run

    MetricsService.digest_email_generation(digest_run.range) do
      Email.transaction do
        generate_email_and_subscription_contents
        digest_run_subscriber.mark_complete!
      end

      DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_digest)

      digest_run.check_and_mark_complete!
    end
  end

private

  attr_reader :digest_run, :digest_run_subscriber, :email, :results, :subscriber

  def generate_email_and_subscription_contents
    @email = create_email

    SubscriptionContent.import!(
      formatted_subscription_content_change_columns,
      formatted_subscription_content_changes,
    )
  end

  def formatted_subscription_content_change_columns
    %i(email_id subscription_id content_change_id digest_run_subscriber_id)
  end

  def formatted_subscription_content_changes
    subscriber_content_changes.flat_map do |result|
      result.content_changes.map do |content_change|
        [
          email.id,
          result.subscription_id,
          content_change.id,
          digest_run_subscriber.id,
        ]
      end
    end
  end

  def create_email
    DigestEmailBuilder.call(
      subscriber: subscriber,
      digest_run: digest_run,
      subscription_content_change_results: subscriber_content_changes,
    )
  end

  def subscriber_content_changes
    @subscriber_content_changes ||= SubscriptionContentChangeQuery.call(
      subscriber: subscriber,
      digest_run: digest_run
    )
  end
end
