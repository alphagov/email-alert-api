class ProcessMessageWorker
  include Sidekiq::Worker

  def perform(message_id)
    message = Message.find(message_id)
    return if message.processed?

    MatchedMessageGenerationService.call(message)
    import_subscription_content(message)
    queue_courtesy_email(message)

    message.mark_processed!
  end

private

  def import_subscription_content(message)
    SubscriptionContent.import_ignoring_duplicates(
      %i(message_id subscription_id),
      subscription_ids(message).map { |id| [message.id, id] },
    )

    ImmediateEmailGenerationWorker.perform_async
  end

  def subscription_ids(message)
    Subscription
      .for_message(message)
      .active
      .immediately
      .subscription_ids_by_subscriber
      .values
      .flatten
  end

  def queue_courtesy_email(message)
    subscriber = Subscriber.find_by(address: Email::COURTESY_EMAIL)
    return unless subscriber

    email_id = MessageEmailBuilder.call([
      {
        address: subscriber.address,
        subscriptions: [],
        message: message,
        subscriber_id: subscriber.id,
      },
    ]).ids.first

    DeliveryRequestWorker.perform_async_in_queue(
      email_id, queue: :delivery_immediate
    )
  end
end
