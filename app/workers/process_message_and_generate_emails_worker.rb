class ProcessMessageAndGenerateEmailsWorker < ProcessAndGenerateEmailsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :process_and_generate_emails

  def perform(message_id)
    message = Message.find(message_id)
    return if message.processed?

    MatchedMessageGenerationService.call(message)
    import_subscription_content(message)

    SubscribersForImmediateEmailQuery.call(content_change_id: nil, message_id: message_id).find_in_batches(batch_size: BATCH_SIZE) do |group|
      email_data = []
      email_ids = {}
      ActiveRecord::Base.transaction do
        subscription_contents = UnprocessedSubscriptionContentsBySubscriberQuery.call(group.pluck(:id))
        if subscription_contents.any?
          update_message_cache(subscription_contents)
          email_data, email_ids = create_message_emails(group, subscription_contents)
        end
      end
      queue_for_delivery(email_data, email_ids)
    end
    queue_courtesy_email(message)
    message.mark_processed!
  end

private

  def import_subscription_content(message)
    ensure_subscription_content_import_running_only_once(message) do
      SubscriptionContent.import_ignoring_duplicates(
        %i(message_id subscription_id),
        subscription_ids(message).map { |id| [message.id, id] },
      )
    end
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

  def queue_courtesy_email(message)
    subscriber = Subscriber.find_by(address: Email::COURTESY_EMAIL)
    return unless subscriber

    email_id = MessageEmailBuilder.call([
      {
        address: subscriber.address,
        subscriptions: [],
        message: message,
        subscriber_id: subscriber.id,
      },
    ]).ids.first

    DeliveryRequestWorker.perform_async_in_queue(
      email_id, queue: :delivery_immediate
    )
  end
end
