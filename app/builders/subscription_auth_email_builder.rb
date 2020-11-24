class SubscriptionAuthEmailBuilder
  def initialize(address:, token:, subscriber_list:, frequency:)
    @address = address
    @token = token
    @subscriber_list = subscriber_list
    @frequency = frequency
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
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

  attr_reader :address, :token, :frequency, :subscriber_list

  def subject
    "Confirm your subscription"
  end

  def body
    <<~BODY
      # Click the link to confirm that you want to get emails from GOV.UK

      # [Yes, I want emails about #{subscriber_list.title}](#{link})

      This link will stop working after 7 days.

      #{I18n.t!("emails.subscription_auth.frequency.#{frequency}")}. You can change this at any time.

      If you did not request this email, you can ignore it.

      Thanks 
      GOV.UK emails 
      [https://www.gov.uk/help/update-email-notifications](https://www.gov.uk/help/update-email-notifications)
    BODY
  end

  def link
    Plek.new.website_uri.tap do |uri|
      uri.path = "/email/subscriptions/authenticate"
      uri.query = "token=#{token}&topic_id=#{subscriber_list.slug}&frequency=#{frequency}"
    end
  end
end
