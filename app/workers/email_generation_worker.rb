class EmailGenerationWorker
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(subscription_content_id:, priority:)
    subscription_content = SubscriptionContent.find(subscription_content_id)

    email = Email.create_from_params!(email_params(subscription_content))

    subscription_content.update!(email: email)

    DeliveryRequestWorker.perform_async_with_priority(
      email.id, priority: priority.to_sym
    )
  end

private

  def email_params(subscription_content)
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
