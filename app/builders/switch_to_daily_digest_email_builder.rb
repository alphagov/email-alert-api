class SwitchToDailyDigestEmailBuilder
  def initialize(subscriber, subscriptions)
    @subscriber = subscriber
    @subscriptions = subscriptions
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.create!(
      address: subscriber.address,
      subject: "Your GOV.UK email subscriptions",
      body: body,
      subscriber_id: subscriber.id,
    ).id
  end

  private_class_method :new

private

  attr_reader :subscriber, :subscriptions

  def body
    <<~BODY
      From now on, we'll group all the emails you get together into one digest when there's a change to content covered by one of these subscriptions:

      #{subscriptions.map { |subscription| "- #{subscription.subscriber_list.title}" }.join("\n")}

      If you need to keep receiving immediate emails you can change this by [managing your email subscriptions](#{manage_subscriptions_link}).
    BODY
  end

  def manage_subscriptions_link
    utm_campaign = "govuk-notifications-switch-to-daily-experiment"
    utm_medium = "email"
    utm_source = "gov.uk"
    utm_content = "manage-subscriptions"
    base_url = PublicUrls.authenticate_url(address: subscriber.address)
    "#{base_url}&utm_source=#{utm_source}&utm_medium=#{utm_medium}&utm_campaign=#{utm_campaign}&utm_content=#{utm_content}"
  end
end
