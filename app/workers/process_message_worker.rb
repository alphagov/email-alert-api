class ProcessMessageWorker < ApplicationWorker
  sidekiq_options queue: :process_and_generate_emails

  def perform(message_id)
    run_with_advisory_lock(Message, message_id) do
      message = Message.find(message_id)
      return if message.processed_at

      MatchedMessageGenerationService.call(message)
      ImmediateEmailGenerationService.call(message)

      queue_courtesy_email(message)
      message.update!(processed_at: Time.zone.now)
    end
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

    SendEmailWorker.perform_async_in_queue(id, queue: message.queue)
  end
end
