class EmailSenderService
  def initialize(config)
    @email_override = config[:email_override]
    @provider = provider(config.fetch(:provider))
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

  def use_notify_provider?(configured_provider)
    configured_provider == "NOTIFY"
  end

  def use_pseudo_provider?(configured_provider)
    configured_provider == "PSEUDO" ||
      configured_provider.nil?
  end

  def provider(configured_provider)
    return Notify.new if use_notify_provider?(configured_provider)
    return Pseudo.new if use_pseudo_provider?(configured_provider)
    raise "Email service provider #{configured_provider} does not exist"
  end
end
