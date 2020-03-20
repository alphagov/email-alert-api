class SubscriberAuthEmailBuilder
  def initialize(subscriber:, destination:, token:)
    @subscriber = subscriber
    @destination = destination
    @token = token
  end

  def self.call(*args)
    new(*args).call
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

  attr_reader :subscriber, :destination, :token

  def subject
    "Manage your GOV.UK email subscriptions"
  end

  def body
    <<~BODY
      # Manage your GOV.UK email subscriptions

      You can unsubscribe from emails or change your subscription at:

      #{link}

      You’ll need to confirm your email address before you can make any changes.

      The link will stop working in 7 days.

      # Didn’t request this email?

      Ignore or delete this email if you didn’t request it. Your subscriptions won’t be changed.

      [Contact GOV.UK](https://www.gov.uk/contact/govuk) if you have any problems with your email subscriptions.
    BODY
  end

  def link
    Plek.new.website_uri.tap do |uri|
      destination_uri = URI.parse(destination)
      uri.path = destination_uri.path
      uri.query = if destination_uri.query.present?
                    "#{destination_uri.query}&token=#{token}"
                  else
                    "token=#{token}"
                  end
      uri.fragment = destination_uri.fragment
    end
  end
end
