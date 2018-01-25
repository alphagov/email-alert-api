class EmailGenerationService
  LOCK_NAME = "email_generation_worker".freeze

  def self.call(*args)
    new.call(*args)
  end

  def call
    ensure_only_running_once do
      subscription_contents.find_in_batches do |group|
        to_queue = []

        SubscriptionContent.transaction do
          email_ids = build_and_insert_emails(group).ids

          values = group.zip(email_ids).map do |subscription_content, email_id|
            to_queue << [email_id, subscription_content.content_change.priority.to_sym]
            "(#{subscription_content.id}, #{email_id})"
          end

          ActiveRecord::Base.connection.execute(%(
            UPDATE subscription_contents SET email_id = v.email_id
            FROM (VALUES #{values.join(',')}) AS v(id, email_id)
            WHERE subscription_contents.id = v.id
          ))
        end

        queue_delivery_request_workers(to_queue)
      end
    end
  end

private

  def ensure_only_running_once
    SubscriptionContent.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      yield
    end
  end

  def queue_delivery_request_workers(queue)
    queue.each do |email_id, priority|
      DeliveryRequestWorker.perform_async_with_priority(
        email_id, priority: priority
      )
    end
  end

  def subscription_contents
    SubscriptionContent
      .joins(:content_change, subscription: { subscriber: { subscriptions: :subscriber_list } })
      .includes(:content_change, subscription: { subscriber: { subscriptions: :subscriber_list } })
      .where.not(subscribers: { address: nil })
      .where(email: nil)
  end

  def build_many_emails(subscription_contents)
    subscription_contents.map do |subscription_content|
      build_email(subscription_content: subscription_content)
    end
  end

  def build_and_insert_emails(subscription_contents)
    emails = build_many_emails(subscription_contents)
    Email.import!(emails)
  end

  def build_email(subscription_content:)
    ImmediateEmailBuilder.call(
      subscriber: subscription_content.subscription.subscriber,
      content_change: subscription_content.content_change
    )
  end
end
