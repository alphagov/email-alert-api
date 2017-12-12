require "sidekiq-scheduler"

class EmailGenerationWorker
  include Sidekiq::Worker

  LOCK_NAME = "email_generation_worker".freeze

  sidekiq_options unique: :until_and_while_executing

  def perform
    SubscriptionContent.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      subscription_contents.find_each do |subscription_content|
        email = create_email(subscription_content: subscription_content)
        subscription_content.email = email
        subscription_content.save

        DeliveryRequestWorker.perform_async_with_priority(
          email.id, priority: subscription_content.content_change.priority.to_sym
        )
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
    Email.create_from_params!(email_params(subscription_content: subscription_content))
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
