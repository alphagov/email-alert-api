class SubscriptionAuthEmailBuilder
  def initialize(address:, token:, topic_id:, frequency:)
    @address = address
    @token = token
    @topic_id = topic_id
    @frequency = frequency
  end

  def self.call(...)
    new(...).call
  end

  def call
    Email.create!(
      subject: subject,
      body: body,
      address: address,
    )
  end

  private_class_method :new

private

  attr_reader :address, :token, :frequency, :topic_id

  def subject
    "Confirm your subscription"
  end

  def body
    <<~BODY
      # Click the link to confirm your subscription

      ^ [Confirm your subscription](#{link})

      This link will stop working in 7 days.

      # Didn’t request this email?

      Ignore or delete this email if you didn’t request it.

      [Read our privacy policy (opens in a new tab)](https://www.gov.uk/help/privacy-notice) to find out how we use and protect your data.

      [Contact GOV.UK](https://www.gov.uk/contact/govuk) if you have any problems with your email subscriptions.
    BODY
  end

  def link
    Plek.new.website_uri.tap do |uri|
      uri.path = "/email/subscriptions/authenticate"
      uri.query = "token=#{token}&topic_id=#{topic_id}&frequency=#{frequency}"
    end
  end
end
