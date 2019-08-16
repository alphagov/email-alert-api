class ProcessContentChangeWorker
  include Sidekiq::Worker

  def perform(content_change_id)
    content_change = ContentChange.find(content_change_id)
    return if content_change.processed?

    import_subscription_content(content_change)
    queue_courtesy_email(content_change)

    content_change.mark_processed!
  end

private

  def import_subscription_content(content_change)
    SubscriptionContent.import_ignoring_duplicates(
      %i(content_change_id subscription_id),
      subscription_ids(content_change).map { |id| [content_change.id, id] },
    )

    ImmediateEmailGenerationWorker.perform_async
  end

  def subscription_ids(content_change)
    Subscription
      .for_content_change(content_change)
      .active
      .immediately
      .subscription_ids_by_subscriber
      .values
      .flatten
  end

  def queue_courtesy_email(content_change)
    subscriber = Subscriber.find_by(address: Email::COURTESY_EMAIL)
    return unless subscriber

    email_id = ContentChangeEmailBuilder.call([
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
