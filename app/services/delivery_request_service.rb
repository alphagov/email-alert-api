class DeliveryRequestService
  PROVIDERS = {
    "notify" => NotifyProvider,
    "pseudo" => PseudoProvider,
  }.freeze

  def self.call(*args)
    new.call(*args)
  end

  attr_accessor :provider_name, :provider, :subject_prefix, :overrider

  def initialize(config: EmailAlertAPI.config.email_service)
    self.provider_name = config.fetch(:provider).downcase
    self.provider = PROVIDERS.fetch(provider_name)
    self.subject_prefix = config.fetch(:email_subject_prefix)
    self.overrider = EmailAddressOverrider.new(config)
  end

  def call(email:)
    raise ArgumentError, "email cannot be nil" if email.nil?

    subject = "#{subject_prefix}#{email.subject}"
    reference = generate_reference(email)
    address = overrider.address(email, subject, reference)

    MetricsService.email_send_request(provider_name) do
      provider.call(
        address: address,
        subject: subject,
        body: email.body,
        reference: reference,
      )
    end

    status = :sending
  rescue ProviderError
    status = :technical_failure
  ensure
    MetricsService.first_delivery_attempt(email, Time.now.utc)

    DeliveryAttempt.create!(
      email: email,
      status: status,
      provider: provider_name,
      reference: reference,
    )
  end

private

  def generate_reference(email)
    timestamp = Time.now.to_s(:iso8601)
    "delivery-attempt-for-email-#{email.id}-sent-to-notify-at-#{timestamp}"
  end

  class EmailAddressOverrider
    attr_accessor :email_address_override

    def initialize(config)
      self.email_address_override = config[:email_address_override]
    end

    def address(email, subject, reference)
      return email.address unless email_address_override

      Rails.logger.info(<<-INFO.strip_heredoc)
        Sending email to #{email.address} (overridden to #{email_address_override})
        Subject: #{subject}
        Reference: #{reference}
        Body: #{email.body}
      INFO

      email_address_override
    end
  end
end
