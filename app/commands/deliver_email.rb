class DeliverEmail
  attr_reader :email

  def initialize(email:)
    @email = email
    raise ArgumentError, "email cannot be nil" if email.nil?
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    email_sender.call(
      address: email.address,
      subject: email.subject,
      body: email.body,
    )
  end

private

  def email_sender
    Services.email_sender
  end
end
