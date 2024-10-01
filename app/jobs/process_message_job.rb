class ProcessMessageJob < ApplicationJob
  sidekiq_options queue: :process_and_generate_emails

  def perform(message_id)
    run_with_advisory_lock(Message, message_id) do
      message = Message.find(message_id)
      return if message.processed_at

      MatchedMessageGenerationService.call(message)
      ImmediateEmailGenerationService.call(message)

      message.update!(processed_at: Time.zone.now)
    end
  end
end
