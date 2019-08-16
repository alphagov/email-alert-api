class ImmediateEmailGenerationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :email_generation_immediate

  LOCK_NAME = "immediate_email_generation_worker".freeze

  def perform
    ensure_only_running_once do
      SubscribersForImmediateEmailQuery.call.find_in_batches do |group|
        subscription_contents = grouped_subscription_contents(group.pluck(:id))
        update_content_change_cache(subscription_contents)
        create_content_change_emails(group, subscription_contents)
      end
    end
  end

private

  def ensure_only_running_once
    Subscriber.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      yield
    end
  end

  def grouped_subscription_contents(subscriber_ids)
    UnprocessedSubscriptionContentsBySubscriberQuery.call(subscriber_ids)
  end

  def content_changes
    @content_changes ||= {}
  end

  def update_content_change_cache(subscription_contents)
    content_change_ids = subscription_contents.flat_map { |_, sc| sc.map(&:content_change_id) }
                                              .compact
                                              .uniq
    ids = content_change_ids - content_changes.keys

    content_changes.merge!(ContentChange.where(id: ids).index_by(&:id))
  end

  def create_content_change_emails(subscribers, subscription_contents)
    email_data = subscribers.flat_map do |subscriber|
      subscribers_content_change_email_data(subscriber,
                                            subscription_contents[subscriber.id])
    end

    email_ids = ContentChangeEmailBuilder.call(email_data.map { |e| e[:params] }).ids
    update_subscription_contents(email_data, email_ids)
    queue_for_delivery(email_data, email_ids)
  end

  def subscribers_content_change_email_data(subscriber, subscription_contents)
    by_content_change_id = subscription_contents.select(&:content_change_id)
                                                .group_by(&:content_change_id)

    by_content_change_id.map do |content_change_id, matching_subscription_contents|
      {
        params: {
          address: subscriber.address,
          content_change: content_changes[content_change_id],
          subscriptions: matching_subscription_contents.map(&:subscription),
          subscriber_id: subscriber.id,
        },
        subscription_contents: matching_subscription_contents,
        priority: content_changes[content_change_id].priority.to_sym,
      }
    end
  end

  def update_subscription_contents(email_data, email_ids)
    values = email_data.flat_map.with_index do |data, index|
      data[:subscription_contents].map do |subscription_content|
        "(#{subscription_content.id}, '#{email_ids[index]}'::UUID)"
      end
    end

    ActiveRecord::Base.connection.execute(
      %(
        UPDATE subscription_contents SET email_id = v.email_id
        FROM (VALUES #{values.join(',')}) AS v(id, email_id)
        WHERE subscription_contents.id = v.id
      )
    )
  end

  def queue_for_delivery(email_data, email_ids)
    email_data.each.with_index do |data, index|
      queue = data[:priority] == :high ? :delivery_immediate_high : :delivery_immediate
      DeliveryRequestWorker.perform_async_in_queue(email_ids[index], queue: queue)
    end
  end
end
