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
    # @TODO make this better
    "Log into your Subsciption Management"
  end

  def body
    # @TODO make this better as well
    <<-BODY
      [Subscription Management](#{link})
    BODY
  end

  def link
    Plek.new.website_uri.tap do |uri|
      uri.path = destination
      uri.query = "token=#{token}"
    end
  end
end
