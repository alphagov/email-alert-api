class SubscriptionContentWorker
  include Sidekiq::Worker

  def perform(content_change_id, batch_size = 1000)
    content_change = ContentChange.find(content_change_id)
    return if content_change.processed?

    queue_delivery_to_subscribers(content_change, batch_size: batch_size)
    queue_delivery_to_courtesy_subscribers(content_change)

    content_change.mark_processed!
  end

private

  def queue_delivery_to_subscribers(content_change, batch_size: 1000)
    content_change_id = content_change.id
    batch = []

    grouped_subscription_ids_by_subscriber(content_change).each do |subscription_ids|
      records = subscription_ids.map do |subscription_id|
        [content_change_id, subscription_id]
      end

      batch.concat(records)

      if batch.size >= batch_size
        import_subscription_contents_batch(batch)
        batch.clear
      end
    end

    import_subscription_contents_batch(batch) unless batch.empty?
  end

  def import_subscription_contents_batch(batch)
    columns = %i(content_change_id subscription_id)

    begin
      SubscriptionContent.transaction do
        SubscriptionContent.import!(columns, batch)
      end
    rescue ActiveRecord::RecordNotUnique
      handle_failed_subscription_content_import(batch)
    end

    ImmediateEmailGenerationWorker.perform_async
  end

  def handle_failed_subscription_content_import(batch)
    SubscriptionContent.transaction do
      batch.each do |(content_change_id, subscription_id)|
        params = { content_change_id: content_change_id, subscription_id: subscription_id }
        SubscriptionContent.create!(params) unless SubscriptionContent.where(params).exists?
      end
    end
  end

  def grouped_subscription_ids_by_subscriber(content_change)
    ContentChangeImmediateSubscriptionQuery.call(content_change: content_change)
      .group(:subscriber_id)
      .pluck("ARRAY_AGG(subscriptions.id)")
  end

  def queue_delivery_to_courtesy_subscribers(content_change)
    addresses = [
      "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk",
    ]

    Subscriber.where(address: addresses).find_each do |subscriber|
      email_id = ImmediateEmailBuilder.call([
        {
          address: subscriber.address,
          subscriptions: [],
          content_change: content_change,
          subscriber_id: subscriber.id,
        }
      ]).ids.first

      DeliveryRequestWorker.perform_async_in_queue(
        email_id, queue: :delivery_immediate,
      )
    end
  end
end
