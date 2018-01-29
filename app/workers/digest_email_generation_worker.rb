class DigestEmailGenerationWorker
  include Sidekiq::Worker

  def perform(digest_run_subscriber_id)
    @digest_run_subscriber = DigestRunSubscriber.find(digest_run_subscriber_id)
    @subscriber = digest_run_subscriber.subscriber
    @digest_run = digest_run_subscriber.digest_run

    Email.transaction do
      generate_email_and_subscription_contents
      digest_run_subscriber.mark_complete!
    end

    DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_digest)

    update_digest_run
  end

private

  attr_reader :digest_run, :digest_run_subscriber, :email, :results, :subscriber

  def generate_email_and_subscription_contents
    @email = create_email

    SubscriptionContent.import!(
      formatted_subscription_content_changes
    )
  end

  def formatted_subscription_content_changes
    subscriber_content_changes.flat_map do |result|
      result.content_changes.map do |content_change|
        {
          email_id: email.id,
          subscription_id: result.subscription_id,
          content_change_id: content_change.id,
          digest_run_subscriber_id: digest_run_subscriber.id,
        }
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

  def update_digest_run
    digest_run.mark_complete! unless DigestRunSubscriber.incomplete_for_run(digest_run.id).exists?
  end
end
