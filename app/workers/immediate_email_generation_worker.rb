class ImmediateEmailGenerationWorker < ProcessAndGenerateEmailsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_immediate

  LOCK_NAME = "immediate_email_generation_worker".freeze

  def perform
    ensure_only_running_once do
      SubscribersForImmediateEmailQuery.call.find_in_batches(batch_size: BATCH_SIZE) do |group|
        content_change_email_data = []
        content_change_email_ids = {}
        message_email_data = []
        message_email_ids = {}
        ActiveRecord::Base.transaction do
          subscription_contents = UnprocessedSubscriptionContentsBySubscriberQuery.call(group.pluck(:id))
          if subscription_contents.any?
            update_content_change_cache(subscription_contents)
            update_message_cache(subscription_contents)
            content_change_email_data, content_change_email_ids = create_content_change_emails(group, subscription_contents)
            message_email_data, message_email_ids = create_message_emails(group, subscription_contents)
          end
        end
        queue_for_delivery(content_change_email_data, content_change_email_ids)
        queue_for_delivery(message_email_data, message_email_ids)
      end
    end
  end

private

  def ensure_only_running_once
    Subscriber.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      yield
    end
  end
end
