class SubscriptionConfirmationEmailBuilder
  def initialize(subscription:)
    @subscription = subscription
  end

  def self.call(...)
    new(...).call
  end

  def call
    Email.create!(
      subject: subject,
      body: body,
      address: subscriber.address,
      subscriber_id: subscriber.id,
    )
  end

  private_class_method :new

private

  attr_reader :subscription

  def subscriber
    @subscriber ||= subscription.subscriber
  end

  def subscriber_list
    @subscriber_list ||= subscription.subscriber_list
  end

  def subject
    "You've subscribed to #{subscriber_list.title}"
  end

  def body
    <<~BODY
      You’ll get an email each time there are changes to #{title}.

      #{subscriber_list.description}

      ---

      #{ManageSubscriptionsLinkPresenter.call(subscriber.address)}
    BODY
  end

  def title
    return subscriber_list.title unless subscriber_list.url

    "[#{subscriber_list.title}](#{title_url})"
  end

  def title_url
    query = {
      utm_source: subscriber_list.slug,
      utm_medium: "email",
      utm_campaign: "govuk-notifications-subscription-confirmation",
    }.to_query

    url = subscriber_list.url
    tracked_url = url + (url.include?("?") ? "&" : "?") + query

    PublicUrls.url_for(base_path: tracked_url)
  end
end
