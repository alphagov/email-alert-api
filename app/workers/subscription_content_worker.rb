class SubscriptionContentWorker
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(content_change_id:, priority:)
    @priority = priority
    content_change = ContentChange.find(content_change_id)
    queue_delivery_to_subscribers(content_change)
    queue_delivery_to_courtesy_subscribers(content_change)
  end

private

  attr_reader :priority

  def queue_delivery_to_subscribers(content_change)
    subscriptions_for(content_change: content_change).find_each do |subscription|
      begin
        subscription_content = SubscriptionContent.create!(
          content_change: content_change,
          subscription: subscription,
        )

        EmailGenerationWorker.perform_async(
          subscription_content_id: subscription_content.id,
          priority: priority.to_sym
        )
      rescue StandardError => ex
        Raven.capture_exception(ex, tags: { version: 2 })
      end
    end
  end

  def queue_delivery_to_courtesy_subscribers(content_change)
    addresses = [
      "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk",
    ]

    Subscriber.where(address: addresses).find_each do |subscriber|
      begin
        email = Email.create_from_params!(
          email_params(content_change, subscriber)
        )

        DeliveryRequestWorker.perform_async_with_priority(
          email.id, priority: priority.to_sym
        )
      rescue StandardError => ex
        Raven.capture_exception(ex, tags: { version: 2 })
      end
    end
  end

  def subscriptions_for(content_change:)
    SubscriptionMatcher.call(content_change: content_change)
  end

  def email_params(content_change, subscriber)
    {
      content_change_id: content_change.id,
      subscriber: subscriber,
      title: content_change.title,
      change_note: content_change.change_note,
      description: content_change.description,
      base_path: content_change.base_path,
      public_updated_at: content_change.public_updated_at,
    }
  end
end
