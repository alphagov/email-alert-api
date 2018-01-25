class SubscriptionContentWorker
  include Sidekiq::Worker

  def perform(content_change_id)
    content_change = ContentChange.find(content_change_id)
    queue_delivery_to_subscribers(content_change)
    queue_delivery_to_courtesy_subscribers(content_change)
    content_change.mark_processed!
  end

private

  def queue_delivery_to_subscribers(content_change)
    subscriptions_for(content_change: content_change).find_in_batches do |group|
      records = group.map do |subscription|
        {
          content_change_id: content_change.id,
          subscription_id: subscription.id,
        }
      end

      begin
        SubscriptionContent.import!(records)
      rescue StandardError => ex
        Raven.capture_exception(ex, tags: { version: 2 })
      end

      ImmediateEmailGenerationWorker.perform_async
    end
  end

  def queue_delivery_to_courtesy_subscribers(content_change)
    addresses = [
      "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk",
    ]

    Subscriber.where(address: addresses).find_each do |subscriber|
      begin
        email_id = ImmediateEmailBuilder.call([
          { subscriber: subscriber, content_change: content_change }
        ]).ids.first

        DeliveryRequestWorker.perform_async_with_priority(
          email_id, priority: content_change.priority.to_sym,
        )
      rescue StandardError => ex
        Raven.capture_exception(ex, tags: { version: 2 })
      end
    end
  end

  def subscriptions_for(content_change:)
    ContentChangeSubscriptionQuery.call(content_change: content_change)
  end

  def email_params(content_change, subscriber)
    {
      subscriber: subscriber,
      title: content_change.title,
      change_note: content_change.change_note,
      description: content_change.description,
      base_path: content_change.base_path,
      public_updated_at: content_change.public_updated_at,
    }
  end
end
