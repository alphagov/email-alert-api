class SubscriptionConfirmationEmailBuilder < ApplicationBuilder
  def initialize(subscription:)
    @subscription = subscription
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

  attr_reader :subscription

  def subscriber
    @subscriber ||= subscription.subscriber
  end

  def subscriber_list
    @subscriber_list ||= subscription.subscriber_list
  end

  def subject
    "You’ve subscribed to #{subscriber_list.title}"
  end

  def body
    <<~BODY
      #{title_and_optional_url}

      ---

      #{ManageSubscriptionsLinkPresenter.call(subscriber.address)}
    BODY
  end

  def title_and_optional_url
    result = "You’ll get an email each time there are changes to #{subscriber_list.title}"

    source_url = SourceUrlPresenter.call(
      subscriber_list.url,
      utm_source: subscriber_list.slug,
      utm_content: "confirmation",
    )

    result += "\n\n" + source_url if source_url
    result
  end
end
