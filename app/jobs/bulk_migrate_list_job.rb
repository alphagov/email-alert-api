class BulkMigrateListJob < ApplicationJob
  def perform(source_list_id, destination_list_id)
    @source_list_id = source_list_id
    @destination_list_id = destination_list_id

    run_with_advisory_lock(SubscriberList, source_list_id) do
      if subscribers_to_move_count.zero?
        logger.warn("no active subscriptions for #{source_list.title}")
        return
      end

      migrate_subscribers_and_confirm
    end
  end

private

  def source_list
    @source_list ||= SubscriberList.find(@source_list_id)
  end

  def destination_list
    @destination_list ||= SubscriberList.find(@destination_list_id)
  end

  def subscribers_to_move_count
    @subscribers_to_move_count ||= source_list.active_subscriptions_count
  end

  def migrate_subscribers_and_confirm
    subscribers = source_list.subscribers
    subscribers.each do |subscriber|
      Subscription.transaction do
        existing_subscription = Subscription.active.find_by(
          subscriber:,
          subscriber_list: source_list,
        )

        next unless existing_subscription

        existing_subscription.end(reason: :bulk_migrated)

        destination_subscriber_list_subscription = Subscription.find_by(
          subscriber:,
          subscriber_list: destination_list,
        )

        if destination_subscriber_list_subscription.blank?
          Subscription.create!(
            subscriber:,
            subscriber_list: destination_list,
            frequency: existing_subscription.frequency,
            source: :subscriber_list_changed,
          )
        end
      end
    end
    send_confirmation_message
  end

  def send_confirmation_message
    remaining_active_subscriptions = Subscription.active.find_by(subscriber_list_id: source_list.id)

    if remaining_active_subscriptions.nil?
      email = BulkMigrateConfirmationEmailBuilder.call(
        source_id: source_list.id,
        destination_id: destination_list.id,
        count: subscribers_to_move_count,
      )
      SendEmailJob.perform_async_in_queue(email.id, queue: :send_email_transactional)
      logger.info("Migration of subscriberlist #{source_list.id} complete. Email with id #{email.id} queued for delivery")
    end
  end
end
