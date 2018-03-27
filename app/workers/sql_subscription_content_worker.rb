class SqlSubscriptionContentWorker
  include Sidekiq::Worker

  def perform(content_change_id)
    content_change = ContentChange.find(content_change_id)
    return if content_change.processed?

    insert_subscription_contents(content_change_id)
    queue_delivery_to_courtesy_subscribers(content_change)

    ImmediateEmailGenerationWorker.perform_async

    content_change.mark_processed!
  end

private

  def insert_subscription_contents(content_change_id)
    SubscriptionContentsImmediateInsert.call(content_change_id: content_change_id)
  end

  def queue_delivery_to_courtesy_subscribers(content_change)
    addresses = [
      "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk",
    ]

    Subscriber.where(address: addresses).find_each do |subscriber|
      email_id = ImmediateEmailBuilder.call([
        { address: subscriber.address, subscriptions: [], content_change: content_change }
      ]).ids.first

      DeliveryRequestWorker.perform_async_in_queue(
        email_id, queue: :delivery_immediate,
      )
    end
  end
end
