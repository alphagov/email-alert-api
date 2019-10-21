class ProcessMessageWorker
  include Sidekiq::Worker

  def perform(message_id)
    message = Message.find(message_id)
    return if message.processed?

    MatchedMessageGenerationService.call(message)
    import_subscription_content(message)
    QueueCourtesyEmailService.call(MessageEmailBuilder, message: message)

    message.mark_processed!
  end

private

  def import_subscription_content(message)
    SubscriptionContent.import_ignoring_duplicates(
      %i(message_id subscription_id),
      SubscriptionsForSubscriptionContentQuery
        .call(:for_message, message)
        .map { |id| [message.id, id] },
    )

    ImmediateEmailGenerationWorker.perform_async
  end
end
