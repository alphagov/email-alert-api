class ImmediateEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_immediate

  LOCK_NAME = "immediate_email_generation_worker".freeze

  attr_reader :content_changes

  def perform
    @content_changes = {}

    ensure_only_running_once do
      subscribers.find_in_batches do |group|
        to_queue = []

        subscription_contents = grouped_subscription_contents(group.pluck(:id))

        update_content_change_cache(subscription_contents)

        Subscriber.transaction do
          values = []

          email_ids = import_emails(group, subscription_contents, content_changes).ids
          subscriber_id_content_change_id_in_order = subscription_contents.flat_map { |k, v| v.map { |x, _y| [k, x] } }

          email_ids.each_with_index do |email_id, i|
            subscriber_id = subscriber_id_content_change_id_in_order[i][0]
            content_change_id = subscriber_id_content_change_id_in_order[i][1]
            subscription_contents_in_this_email = subscription_contents[subscriber_id][content_change_id]

            to_queue << [email_id, content_changes[content_change_id].priority.to_sym]

            subscription_contents_in_this_email.each do |subscription_content|
              values << "(#{subscription_content.id}, #{email_id})"
            end
          end

          update_subscription_contents(values)
        end

        queue_delivery_request_workers(to_queue)
      end
    end
  end

private

  def update_content_change_cache(subscription_contents)
    content_change_ids = subscription_contents.flat_map { |_k, v| v.keys }.uniq
    existing_content_change_ids = content_changes.keys
    missing_content_change_ids = content_change_ids - existing_content_change_ids

    if missing_content_change_ids.any?
      ContentChange.where(id: missing_content_change_ids).each do |cc|
        content_changes[cc.id] = cc
      end
    end
  end

  def ensure_only_running_once
    Subscriber.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
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

  def grouped_subscription_contents(subscriber_ids)
    UnprocessedSubscriptionContentsBySubscriberQuery.call(subscriber_ids)
  end

  def subscribers
    SubscribersForImmediateEmailQuery.call
  end

  def import_emails(subscribers, subscription_contents, content_changes)
    email_params = subscribers.flat_map do |subscriber|
      subscription_contents[subscriber.id].keys.map do |content_change_id|
        {
          address: subscriber.address,
          content_change: content_changes[content_change_id],
          subscriptions: subscription_contents[subscriber.id][content_change_id].map(&:subscription)
        }
      end
    end

    ImmediateEmailBuilder.call(email_params)
  end

  def update_subscription_contents(values)
    ActiveRecord::Base.connection.execute(
      %(
        UPDATE subscription_contents SET email_id = v.email_id
        FROM (VALUES #{values.join(',')}) AS v(id, email_id)
        WHERE subscription_contents.id = v.id
      )
    )
  end
end
