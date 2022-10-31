class SubscriptionConfirmationEmailBuilder
  include Callable

  def initialize(subscription:)
    @subscription = subscription
    @subscriber = subscription.subscriber
    @subscriber_list = subscription.subscriber_list
  end

  def call
    Email.create!(
      subject:,
      body:,
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

      #{title}

      Thanks
      GOV.UK emails

      [Unsubscribe](#{unsubscribe_url})

      [Change your email preferences](#{manage_url})
    BODY
  end

  def title
    if is_single_page_subscription?
      absolute_url = PublicUrls.url_for(
        base_path: subscriber_list.url,
        utm_source: subscriber_list.slug,
        utm_content: "confirmation",
      )
      "[#{subscriber_list.title}](#{absolute_url})"
    else
      subscriber_list.title
    end
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
