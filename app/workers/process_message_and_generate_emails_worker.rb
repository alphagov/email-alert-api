class ProcessMessageAndGenerateEmailsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :process_and_generate_emails

  def perform(message_id)
    message = Message.find(message_id)
    return if message.processed?

    MatchedMessageGenerationService.call(message)
    ImmediateEmailGenerationService.call(message)

    queue_courtesy_email(message)
    message.mark_processed!
  end

private

  def queue_courtesy_email(message)
    subscriber = Subscriber.find_by(address: Email::COURTESY_EMAIL)
    return unless subscriber

    id = MessageEmailBuilder.call([
      {
        address: subscriber.address,
        subscriptions: [],
        message: message,
        subscriber_id: subscriber.id,
      },
    ]).first

    DeliveryRequestWorker.perform_async_in_queue(id, queue: message.queue)
  end
end
