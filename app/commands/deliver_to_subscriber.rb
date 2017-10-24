class DeliverToSubscriber
  attr_reader :subscriber
  attr_reader :email

  def initialize(subscriber:, email:)
    @subscriber = subscriber
    @email = email
    raise ArgumentError, "subscriber cannot be nil" if subscriber.nil?
    raise ArgumentError, "email cannot be nil" if email.nil?
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    email_sender.call(
      address: subscriber.address,
      subject: email.subject,
      body: email.body,
    )
  end

private

  def email_sender
    Services.email_sender
  end
end
