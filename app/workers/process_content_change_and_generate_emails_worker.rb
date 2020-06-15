class ProcessContentChangeAndGenerateEmailsWorker < ProcessAndGenerateEmailsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :process_and_generate_emails

  def perform(content_change_id)
    content_change = ContentChange.find(content_change_id)
    return if content_change.processed?

    MatchedContentChangeGenerationService.call(content_change)

    import_subscription_content(content_change)

    SubscribersForImmediateEmailQuery.call(content_change_id: content_change_id, message_id: nil).find_in_batches(batch_size: BATCH_SIZE) do |group|
      email_data = []
      email_ids = {}
      ActiveRecord::Base.transaction do
        subscription_contents = UnprocessedSubscriptionContentsBySubscriberQuery.call(group.pluck(:id))
        if subscription_contents.any?
          update_content_change_cache(subscription_contents)
          email_data, email_ids = create_content_change_emails(group, subscription_contents)
        end
      end
      queue_for_delivery(email_data, email_ids)
    end
    content_change.mark_processed!
    queue_courtesy_email(content_change)
  end

private

  def import_subscription_content(content_change)
    ensure_subscription_content_import_running_only_once(content_change) do
      SubscriptionContent.import!(
        %i[content_change_id subscription_id],
        subscription_ids(content_change).map { |id| [content_change.id, id] },
        on_duplicate_key_ignore: true,
        batch_size: 500,
      )
    end
  end

  def subscription_ids(content_change)
    Subscription
      .for_content_change(content_change)
      .active
      .immediately
      .subscription_ids_by_subscriber
      .values
      .flatten
  end

  def queue_courtesy_email(content_change)
    subscriber = Subscriber.find_by(address: Email::COURTESY_EMAIL)
    return unless subscriber

    email_id = ContentChangeEmailBuilder.call([
      {
        address: subscriber.address,
        subscriptions: [],
        content_change: content_change,
        subscriber_id: subscriber.id,
      },
    ]).ids.first

    queue = content_change.priority == "high" ? :delivery_immediate_high : :delivery_immediate

    DeliveryRequestWorker.perform_async_in_queue(
      email_id, queue: queue
    )
  end
end
