class ProcessAndGenerateEmailsWorker
  BATCH_SIZE = 5000

  def initialize
    @content_changes = {}
    @messages = {}
  end

private

  attr_accessor :content_changes, :messages

  def ensure_subscription_content_import_running_only_once(content_change_or_message)
    SubscriptionContent.with_advisory_lock("#{content_change_or_message.class.name}_#{content_change_or_message.id}}", timeout_seconds: 0) do
      yield
    end
  end

  def update_content_change_cache(subscription_contents)
    content_change_ids = subscription_contents
      .flat_map { |_, sc| sc.map(&:content_change_id) }
      .compact
      .uniq
    ids = content_change_ids - content_changes.keys

    content_changes.merge!(ContentChange.where(id: ids).index_by(&:id))
  end

  def update_message_cache(subscription_contents)
    message_ids = subscription_contents
      .flat_map { |_, sc| sc.map(&:message_id) }
      .compact
      .uniq
    ids = message_ids - messages.keys

    messages.merge!(Message.where(id: ids).index_by(&:id))
  end

  def create_content_change_emails(subscribers, subscription_contents)
    email_data = subscribers.flat_map do |subscriber|
      subscribers_content_change_email_data(
        subscriber,
        subscription_contents[subscriber.id]
      )
    end

    email_ids = ContentChangeEmailBuilder.call(email_data.map { |e| e[:params] }).ids
    update_subscription_contents(email_data, email_ids)
    [email_data, email_ids]
  end

  def subscribers_content_change_email_data(subscriber, subscription_contents)
    by_content_change_id = subscription_contents
      .to_a
      .select(&:content_change_id)
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

  def create_message_emails(subscribers, subscription_contents)
    email_data = subscribers.flat_map do |subscriber|
      subscribers_message_email_data(
        subscriber,
        subscription_contents[subscriber.id]
      )
    end

    email_ids = MessageEmailBuilder.call(email_data.map { |e| e[:params] }).ids
    update_subscription_contents(email_data, email_ids)
    [email_data, email_ids]
  end

  def subscribers_message_email_data(subscriber, subscription_contents)
    by_message_id = subscription_contents
      .select(&:message_id)
      .group_by(&:message_id)

    by_message_id.map do |message_id, matching_subscription_contents|
      {
        params: {
          address: subscriber.address,
          message: messages[message_id],
          subscriptions: matching_subscription_contents.map(&:subscription),
          subscriber_id: subscriber.id,
        },
        subscription_contents: matching_subscription_contents,
        priority: messages[message_id].priority.to_sym,
      }
    end
  end

  def update_subscription_contents(email_data, email_ids)
    return if email_data.empty?

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
      ),
    )
  end

  def queue_for_delivery(email_data_to_deliver, email_ids_to_deliver)
    email_data_to_deliver.each.with_index do |data, index|
      queue = data[:priority] == :high ? :delivery_immediate_high : :delivery_immediate
      DeliveryRequestWorker.perform_async_in_queue(email_ids_to_deliver[index], queue: queue)
    end
  end
end
