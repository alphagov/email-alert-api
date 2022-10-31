class SubscriptionAuthEmailBuilder
  include Callable

  def initialize(address:, token:, subscriber_list:, frequency:)
    @address = address
    @token = token
    @subscriber_list = subscriber_list
    @frequency = frequency
  end

  def call
    Email.create!(
      subject:,
      body:,
      address:,
    )
  end

private

  attr_reader :address, :token, :frequency, :subscriber_list

  def subject
    "Confirm that you want to get emails from GOV.UK"
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
    BODY
  end

  def link
    PublicUrls.url_for(
      base_path: "/email/subscriptions/authenticate",
      token:,
      topic_id: subscriber_list.slug,
      frequency:,
    )
  end
end
