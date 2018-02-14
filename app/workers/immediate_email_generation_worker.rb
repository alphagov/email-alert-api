class ImmediateEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_immediate

  LOCK_NAME = "immediate_email_generation_worker".freeze

  def perform
    ensure_only_running_once do
      GC.start

      subscription_contents.find_in_batches do |group|
        to_queue = []

        SubscriptionContent.transaction do
          email_ids = import_emails(group).ids

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

      GC.start
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
      DeliveryRequestWorker.perform_async_in_queue(
        email_id, queue: queue_for_priority(priority)
      )
    end
  end

  def queue_for_priority(priority)
    if priority == :high
      :delivery_immediate_high
    elsif priority == :normal
      :delivery_immediate
    else
      raise ArgumentError, "priority should be :high or :normal"
    end
  end

  def subscription_contents
    SubscriptionContent
      .joins(:content_change, subscription: { subscriber: { subscriptions: :subscriber_list } })
      .includes(:content_change, subscription: { subscriber: { subscriptions: :subscriber_list } })
      .where.not(subscribers: { address: nil })
      .where(email: nil)
  end

  def import_emails(subscription_contents)
    subscription_content_changes = subscription_contents.map do |subscription_content|
      {
        subscription: subscription_content.subscription,
        content_change: subscription_content.content_change,
      }
    end

    ImmediateEmailBuilder.call(subscription_content_changes)
  end
end
