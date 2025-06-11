class ProcessContentChangeJob < ApplicationJob
  sidekiq_options queue: :process_and_generate_emails

  def perform(content_change_id)
    run_with_advisory_lock(ContentChange, content_change_id) do
      content_change = ContentChange.find(content_change_id)
      return if content_change.processed_at

      MatchedContentChangeGenerationService.call(content_change)
      UpdateLastAlertedAtSubscriberListService.call(content_change)
      ImmediateEmailGenerationService.call(content_change)

      content_change.update!(processed_at: Time.zone.now)
    end
  end
end
