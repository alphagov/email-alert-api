class EmailSenderService
  def initialize(config, email_service_provider)
    @email_address_override = config[:email_address_override]
    @provider = email_service_provider
  end

  def call(address:, subject:, body:)
    provider.call(
      address: email_address_override || address,
      subject: subject,
      body: body
    )
  end

private

  attr_reader :provider, :email_address_override
end
