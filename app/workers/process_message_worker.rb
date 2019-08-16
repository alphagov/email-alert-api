class ProcessMessageWorker
  include Sidekiq::Worker

  def perform(message_id)
    message = Message.find(message_id)
    return if message.processed?

    import_subscription_content(message)
    # queue_courtesy_email(message) TODO

    message.mark_processed!
  end

private

  def import_subscription_content(message)
    SubscriptionContent.import_ignoring_duplicates(
      %i(message_id subscription_id),
      subscription_ids(message).map { |id| [message.id, id] },
    )

    # ImmediateEmailGenerationWorker.perform_async TODO
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
end
