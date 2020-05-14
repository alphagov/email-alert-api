class DigestEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_digest

  def perform(digest_run_subscriber_id)
    digest_run_subscriber = DigestRunSubscriber.includes(:subscriber, :digest_run)
                                               .find(digest_run_subscriber_id)
    subscription_content = DigestSubscriptionContentQuery.call(
      digest_run_subscriber.subscriber,
      digest_run_subscriber.digest_run,
    )

    if subscription_content.empty?
      digest_run_subscriber.mark_complete!
    else
      create_and_send_email(digest_run_subscriber, subscription_content)
    end
  end

private

  def create_and_send_email(digest_run_subscriber, subscription_content)
    digest_run = digest_run_subscriber.digest_run
    subscriber = digest_run_subscriber.subscriber

    MetricsService.digest_email_generation(digest_run.range) do
      email = nil
      Email.transaction do
        digest_run_subscriber.mark_complete!
        email = DigestEmailBuilder.call(
          address: subscriber.address,
          subscription_content: subscription_content,
          digest_run: digest_run,
          subscriber_id: subscriber.id,
        )
        fill_subscription_content(email, subscription_content, digest_run_subscriber)
      end

      DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_digest)
    end
  end

  def fill_subscription_content(email, subscription_content, digest_run_subscriber)
    columns = %i[email_id
                 subscription_id
                 content_change_id
                 message_id
                 digest_run_subscriber_id]

    rows = subscription_content.flat_map do |result|
      result.content.map do |content|
        [
          email.id,
          result.subscription_id,
          content.is_a?(ContentChange) ? content.id : nil,
          content.is_a?(Message) ? content.id : nil,
          digest_run_subscriber.id,
        ]
      end
    end

    SubscriptionContent.import!(columns, rows)
  end
end
