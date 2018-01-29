class DigestEmailGenerationWorker
  include Sidekiq::Worker

  def perform(subscriber_id:, digest_run_id:)
    @subscriber = Subscriber.find(subscriber_id)
    @digest_run = DigestRun.find(digest_run_id)

    generate_email_and_subscription_contents

    DeliveryRequestWorker.perform_async_with_priority(email.id, priority: :normal)
  end

private

  attr_reader :subscriber, :digest_run, :email, :results

  def generate_email_and_subscription_contents
    Email.transaction do
      @email = create_email

      SubscriptionContent.import!(
        formatted_subscription_content_changes
      )
    end
  end

  def formatted_subscription_content_changes
    subscriber_content_changes.flat_map do |result|
      result.content_changes.map do |content_change|
        {
          email_id: email.id,
          subscription_id: result.subscription_id,
          content_change_id: content_change.id,
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
end
