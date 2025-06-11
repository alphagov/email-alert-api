class BulkUnsubscribeListJob < ApplicationJob
  sidekiq_options queue: :process_and_generate_emails

  def perform(subscriber_list_id, message_id)
    run_with_advisory_lock(SubscriberList, subscriber_list_id) do
      ProcessMessageJob.new.perform(message_id) if message_id

      Subscription.active.where(subscriber_list_id:).update_all(
        ended_reason: :bulk_unsubscribed,
        ended_at: Time.zone.now,
      )
    end
  end
end
