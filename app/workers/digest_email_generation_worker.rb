class DigestEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_digest

  def perform(digest_run_subscriber_id)
    email = nil

    ApplicationRecord.try_lock do
      digest_run_subscriber = DigestRunSubscriber.find(digest_run_subscriber_id)
      return if digest_run_subscriber.processed_at

      digest_items = DigestItemsQuery.call(
        digest_run_subscriber.subscriber,
        digest_run_subscriber.digest_run,
      )

      email = create_email(digest_run_subscriber, digest_items)
      digest_run_subscriber.update!(processed_at: Time.zone.now)
    end

    if email
      DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_digest)
    end
  end

private

  def create_email(digest_run_subscriber, digest_items)
    return if digest_items.empty?

    Metrics.digest_email_generation(digest_run_subscriber.digest_run.range) do
      email = DigestEmailBuilder.call(
        address: digest_run_subscriber.subscriber.address,
        digest_items: digest_items,
        digest_run: digest_run_subscriber.digest_run,
        subscriber_id: digest_run_subscriber.subscriber_id,
      )
      fill_subscription_content(email, digest_items, digest_run_subscriber)

      email
    end
  end

  def fill_subscription_content(email, digest_items, digest_run_subscriber)
    now = Time.zone.now
    records = digest_items.flat_map do |result|
      result.content.map do |content|
        {
          email_id: email.id,
          subscription_id: result.subscription_id,
          content_change_id: content.is_a?(ContentChange) ? content.id : nil,
          message_id: content.is_a?(Message) ? content.id : nil,
          digest_run_subscriber_id: digest_run_subscriber.id,
          created_at: now,
          updated_at: now,
        }
      end
    end

    SubscriptionContent.insert_all!(records)
  end
end
