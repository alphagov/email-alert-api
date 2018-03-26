class DigestEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_digest

  def perform(digest_run_subscriber_id)
    digest_run_subscriber = DigestRunSubscriber.includes(:subscriber, :digest_run).find(digest_run_subscriber_id)
    content_changes = fetch_subscriber_content_changes(digest_run_subscriber)

    if content_changes.count.zero?
      mark_digest_run_completed(digest_run_subscriber)
    else
      create_and_send_email(digest_run_subscriber, content_changes)
    end
  end

private

  def create_and_send_email(digest_run_subscriber, content_changes)
    range = digest_run_subscriber.digest_run.range

    MetricsService.digest_email_generation(range) do
      email = Email.transaction do
        mark_digest_run_completed(digest_run_subscriber)
        generate_email_and_subscription_contents(
          digest_run_subscriber,
          content_changes
        )
      end

      DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_digest)
    end
  end

  def mark_digest_run_completed(digest_run_subscriber)
    digest_run_subscriber.mark_complete!
    digest_run_subscriber.digest_run.check_and_mark_complete!
  end

  def generate_email_and_subscription_contents(digest_run_subscriber, content_changes)
    email = create_email(digest_run_subscriber, content_changes)
    columns = formatted_subscription_content_change_columns
    values = formatted_subscription_content_changes(
      email, digest_run_subscriber, content_changes
    )

    SubscriptionContent.import!(columns, values)

    email
  end

  def formatted_subscription_content_change_columns
    %i(email_id subscription_id content_change_id digest_run_subscriber_id)
  end

  def formatted_subscription_content_changes(email, digest_run_subscriber, content_changes)
    content_changes.flat_map do |result|
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

  def create_email(digest_run_subscriber, content_changes)
    DigestEmailBuilder.call(
      subscriber: digest_run_subscriber.subscriber,
      digest_run: digest_run_subscriber.digest_run,
      subscription_content_change_results: content_changes,
    )
  end

  def fetch_subscriber_content_changes(digest_run_subscriber)
    SubscriptionContentChangeQuery.call(
      subscriber: digest_run_subscriber.subscriber,
      digest_run: digest_run_subscriber.digest_run,
    )
  end
end
