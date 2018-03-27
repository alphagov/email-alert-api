class AuthEmailBuilder
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
    "Confirm your email address"
  end

  def body
    <<~BODY
      # Click the link to confirm your email address

      ^ [Confirm your email address](#{link})

      We need to check that #{subscriber.address} is your email address so that you can manage your GOV.UK email subscriptions. This link will stop working in 7 days.

      # Didn’t request this email?

      Ignore or delete this email if you didn’t request it. Your subscriptions won’t be changed.

      [Contact us](https://www.gov.uk/contact/govuk) if you have problems with your GOV.UK email subscription.
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
