class DigestEmailGenerationJob < ApplicationJob
  sidekiq_options queue: :email_generation_digest

  def perform(digest_run_subscriber_id)
    email_ids = []

    DigestRun.transaction do
      digest_run_subscriber = DigestRunSubscriber.lock.find(digest_run_subscriber_id)
      return if digest_run_subscriber.processed_at

      digest_items = DigestItemsQuery.call(
        digest_run_subscriber.subscriber,
        digest_run_subscriber.digest_run,
      )

      email_ids = digest_items.map do |digest_item|
        email_id = create_email(digest_run_subscriber, digest_item)
        fill_subscription_content(email_id, digest_item, digest_run_subscriber)
        email_id
      end

      digest_run_subscriber.update!(processed_at: Time.zone.now)
    end

    email_ids.each do |email_id|
      SendEmailJob.perform_async_in_queue(email_id, queue: :send_email_digest)
    end
  end

private

  def create_email(digest_run_subscriber, digest_item)
    Metrics.digest_email_generation(digest_run_subscriber.digest_run.range) do
      email = DigestEmailBuilder.call(
        content: digest_item.content,
        subscription: digest_item.subscription,
      )

      email.id
    end
  end

  def fill_subscription_content(email_id, digest_item, digest_run_subscriber)
    now = Time.zone.now

    records = digest_item.content.map do |content|
      {
        email_id:,
        subscription_id: digest_item.subscription.id,
        content_change_id: content.is_a?(ContentChange) ? content.id : nil,
        message_id: content.is_a?(Message) ? content.id : nil,
        digest_run_subscriber_id: digest_run_subscriber.id,
        created_at: now,
        updated_at: now,
      }
    end

    SubscriptionContent.insert_all!(records) if records.any?
  end
end
