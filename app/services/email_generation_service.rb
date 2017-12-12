class EmailGenerationService
  LOCK_NAME = "email_generation_worker".freeze

  def self.call(*args)
    new.call(*args)
  end

  def call
    SubscriptionContent.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      subscription_contents.find_in_batches do |group|
        to_queue = []

        SubscriptionContent.transaction do
          emails = create_and_insert_emails(group)

          values = group.zip(emails).map do |subscription_content, email|
            to_queue << [email.id, subscription_content.content_change.priority.to_sym]
            "(#{subscription_content.id}, #{email.id})"
          end.join(",")

          ActiveRecord::Base.connection.execute(%(
            UPDATE subscription_contents SET email_id = v.email_id
            FROM (VALUES #{values}) AS v(id, email_id)
            WHERE subscription_contents.id = v.id
          ))
        end

        queue_delivery_request_workers(to_queue)
      end
    end
  end

private

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

  def create_many_emails(subscription_contents)
    subscription_contents.map do |subscription_content|
      create_email(subscription_content: subscription_content)
    end
  end

  def create_and_insert_emails(subscription_contents)
    emails = create_many_emails(subscription_contents)
    Email.import!(emails)
    emails
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
