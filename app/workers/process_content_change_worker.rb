class ProcessContentChangeWorker
  include Sidekiq::Worker

  def perform(content_change_id)
    content_change = ContentChange.find(content_change_id)
    return if content_change.processed?

    import_subscription_content(content_change)
    QueueCourtesyEmailService.call(content_change)

    content_change.mark_processed!
  end

private

  def import_subscription_content(content_change)
    SubscriptionContent.import_ignoring_duplicates(
      %i(content_change_id subscription_id),
      SubscriptionsForSubscriptionContentQuery
        .call(:for_content_change, content_change)
        .map { |id| [content_change.id, id] },
    )

    queue = content_change.high? ? :email_generation_immediate_high : :email_generation_immediate
    ImmediateContentChangeEmailGenerationWorker.perform_async_in_queue(content_change.id, queue: queue)
  end
end
