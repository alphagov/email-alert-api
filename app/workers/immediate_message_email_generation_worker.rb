class ImmediateMessageEmailGenerationWorker
  include Sidekiq::Worker
  include ImmediateEmailGeneratorService

  def self.perform_async_in_queue(*args, queue:)
    set(queue: queue).perform_async(*args)
  end

  def perform(message_id)
    ensure_only_running_once("message", message_id) do
      generate_emails(message_id: message_id)
    end
  end
end
