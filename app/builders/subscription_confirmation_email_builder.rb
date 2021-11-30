class SubscriptionConfirmationEmailBuilder
  include Callable

  def initialize(subscription:)
    @subscription = subscription
    @subscriber = subscription.subscriber
    @subscriber_list = subscription.subscriber_list
  end

  def call
    Email.create!(
      subject: subject,
      body: body,
      address: subscriber.address,
      subscriber_id: subscriber.id,
    )
  end

private

  attr_reader :subscription, :subscriber, :subscriber_list

  def subject
    "You’ve subscribed to: #{subscriber_list.title}"
  end

  def body
    <<~BODY
      # You’ve subscribed to GOV.UK emails

      #{frequency}

      #{title_and_optional_url}

      Thanks
      GOV.UK emails

      [Unsubscribe](#{unsubscribe_url})

      [Change your email preferences](#{manage_url})
    BODY
  end

  def title_and_optional_url
    result = title

    source_url = SourceUrlPresenter.call(
      subscriber_list.url,
      utm_source: subscriber_list.slug,
      utm_content: "confirmation",
    )

    result += "\n\n#{source_url}" if source_url
    result
  end

  def title
    is_single_page_subscription? ? "[#{subscriber_list.title}](#{subscriber_list.url})" : subscriber_list.title
  end

  def unsubscribe_url
    PublicUrls.unsubscribe(
      subscription,
      utm_source: subscriber_list.slug,
      utm_content: subscription.frequency,
    )
  end

  def manage_url
    PublicUrls.manage_url(
      subscriber,
      utm_source: subscriber_list.slug,
      utm_content: subscription.frequency,
    )
  end

  def is_single_page_subscription?
    subscriber_list.content_id.present?
  end

  def frequency
    subscription_type = is_single_page_subscription? ? "page" : "topic"
    I18n.t!("emails.confirmation.frequency.#{subscription_type}.#{subscription.frequency}")
  end
end
