class EmailGenerationService
  LOCK_NAME = "email_generation_worker".freeze

  def self.call(*args)
    new.call(*args)
  end

  def call
    SubscriptionContent.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      subscription_contents.find_in_batches(batch_size: 500) do |group|
        to_queue = []

        SubscriptionContent.transaction do
          emails = group.map do |subscription_content|
            create_email(subscription_content: subscription_content)
          end

          Email.import!(emails)

          new_values = group.zip(emails).each_with_object({}) do |(subscription_content, email), hsh|
            to_queue << [email.id, subscription_content.content_change.priority.to_sym]
            hsh[subscription_content.id] = email.id
          end

          values = new_values.map { |id, email_id| "(#{id}, #{email_id})" }.join(",")

          ActiveRecord::Base.connection.execute(%(
            UPDATE subscription_contents SET email_id = v.email_id
            FROM (VALUES #{values}) AS v(id, email_id)
            WHERE subscription_contents.id = v.id
          ))
        end

        to_queue.each do |email_id, priority|
          DeliveryRequestWorker.perform_async_with_priority(
            email_id, priority: priority
          )
        end
      end
    end
  end

private

  def subscription_contents
    SubscriptionContent
      .joins(:content_change, subscription: { subscriber: { subscriptions: :subscriber_list } })
      .includes(:content_change, subscription: { subscriber: { subscriptions: :subscriber_list } })
      .where.not(subscribers: { address: nil })
      .where(email: nil)
  end

  def create_email(subscription_content:)
    Email.build_from_params(email_params(subscription_content: subscription_content))
  end

  def email_params(subscription_content:)
    content_change = subscription_content.content_change

    {
      title: content_change.title,
      change_note: content_change.change_note,
      description: content_change.description,
      base_path: content_change.base_path,
      public_updated_at: content_change.public_updated_at,
      subscriber: subscription_content.subscription.subscriber,
    }
  end
end
