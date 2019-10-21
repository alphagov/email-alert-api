class ImmediateContentChangeEmailGenerationWorker
  include Sidekiq::Worker
  include ImmediateEmailGeneratorService

  def self.perform_async_in_queue(*args, queue:)
    set(queue: queue).perform_async(*args)
  end

  def perform(content_change_id)
    ensure_only_running_once("content_change", content_change_id) do
      generate_emails(content_change_id: content_change_id)
    end
  end
end
