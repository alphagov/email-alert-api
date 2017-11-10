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
    reference = email_sender.call(
      address: email.address,
      subject: email.subject,
      body: email.body,
    )

    record_delivery_attempt(
      email: email,
      status: :sending,
      reference: reference,
    )
  rescue EmailSenderService::ClientError
    record_delivery_attempt(
      email: email,
      status: :technical_failure,
    )
  end

private

  def record_delivery_attempt(email:, status:, reference: "")
    DeliveryAttempt.create!(
      email: email,
      status: status,
      provider: email_sender.provider_name,
      reference: reference,
    )
  end

  def email_sender
    @email_sender ||= Services.email_sender
  end
end
