class DeliverToSubscriber
  attr_reader :subscriber

  def initialize(subscriber:)
    @subscriber = subscriber
    raise ArgumentError, "subscriber cannot be nil" if subscriber.nil?
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    email_sender.call(address: subscriber.address, subject: "", body: "")
  end

private

  def email_sender
    Services.email_sender
  end
end
