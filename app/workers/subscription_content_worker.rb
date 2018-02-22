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
      columns = %i(content_change_id subscription_id)

      content_change_id = content_change.id
      records = group.pluck(:id).map do |subscription_id|
        [content_change_id, subscription_id]
      end

      begin
        SubscriptionContent.import!(columns, records)
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
          { address: subscriber.address, subscriptions: [], content_change: content_change }
        ]).ids.first

        DeliveryRequestWorker.perform_async_in_queue(
          email_id, queue: :delivery_immediate,
        )
      rescue StandardError => ex
        Raven.capture_exception(ex, tags: { version: 2 })
      end
    end
  end

  def subscriptions_for(content_change:)
    ContentChangeImmediateSubscriptionQuery.call(content_change: content_change)
  end
end
