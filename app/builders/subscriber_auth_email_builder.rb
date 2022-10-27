class SubscriberAuthEmailBuilder
  include Callable

  def initialize(subscriber:, destination:, token:)
    @subscriber = subscriber
    @destination = destination
    @token = token
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

  attr_reader :subscriber, :destination, :token

  def subject
    "Change your GOV.UK email preferences"
  end

  def body
    <<~BODY
      # Click the link to confirm your email address

      # [Yes, I want to change my GOV.UK email preferences](#{link})

      This link will stop working after 7 days.

      If you did not request this email, you can ignore it.

      Thanks
      GOV.UK emails
    BODY
  end

  def link
    PublicUrls.url_for(base_path: destination, token:)
  end
end
