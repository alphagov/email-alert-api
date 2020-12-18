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
      We've changed how often you get some emails from GOV.UK. We've done this to make the number of emails you get more manageable.

      You'll now get one email a day that will list any changes to:

      #{subscriptions.map { |subscription| "- #{subscription.subscriber_list.title}" }.join("\n")}

      If you do not get an email about those topics, it's because there have been no changes.

      We’ve not changed how often you get emails for any other GOV.UK subscriptions you may have. We’ve only changed the subscriptions listed in this email.

      # If you want to go back to immediate emails

      You can go back to getting immediate updates about these topics by [managing your subscriptions](#{manage_subscriptions_link}).
    BODY
  end

  def manage_subscriptions_link
    utm_campaign = "govuk-notifications-switch-to-daily-covid-transition"
    utm_medium = "email"
    utm_source = "gov.uk"
    utm_content = "manage-subscriptions"
    base_url = PublicUrls.authenticate_url(address: subscriber.address)
    "#{base_url}&utm_source=#{utm_source}&utm_medium=#{utm_medium}&utm_campaign=#{utm_campaign}&utm_content=#{utm_content}"
  end
end
