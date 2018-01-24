class DigestEmailGenerationWorker
  include Sidekiq::Worker

  attr_reader :subscriber, :digest_run, :email

  def perform(subscriber_id:, digest_run_id:)
    @subscriber = Subscriber.find(subscriber_id)
    @digest_run = DigestRun.find(digest_run_id)

    generate_email_and_subscription_contents

    DeliveryRequestWorker.perform_async_with_priority(email.id, priority: :low)
  end

private

  attr_reader :results

  def generate_email_and_subscription_contents
    @results = subscriber_content_changes
    @email = build_email
    persist_email_and_subscription_contents
  end

  def persist_email_and_subscription_contents
    Email.transaction do
      email.save!

      SubscriptionContent.import!(
        formatted_subscription_content_changes
      )
    end
  end

  def formatted_subscription_content_changes
    results.flat_map do |result|
      result.content_changes.map do |content_change|
        {
          email_id: email.id,
          subscription_id: result.subscription_id,
          content_change_id: content_change.id,
        }
      end
    end
  end

  def build_email
    DigestEmailBuilder.call(
      subscriber: subscriber,
      digest_run: digest_run,
      subscription_content_change_results: results,
    )
  end

  def subscriber_content_changes
    SubscriptionContentChangeQuery.call(
      subscriber: subscriber,
      digest_run: digest_run
    )
  end
end
