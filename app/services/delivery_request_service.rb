class DeliveryRequestService
  PROVIDERS = {
    "notify" => NotifyProvider,
    "pseudo" => PseudoProvider,
  }.freeze

  attr_reader :provider_name, :provider, :subject_prefix, :overrider

  def initialize(config: EmailAlertAPI.config.email_service)
    @provider_name = config.fetch(:provider).downcase
    @provider = PROVIDERS.fetch(provider_name)
    @subject_prefix = config.fetch(:email_subject_prefix)
    @overrider = EmailAddressOverrider.new(config)
  end

  def self.call(*args)
    new.call(*args)
  end

  def call(email:)
    raise ArgumentError, "email cannot be nil" if email.nil?

    subject = "#{subject_prefix}#{email.subject}"
    reference = SecureRandom.uuid
    address = determine_address(email, reference)

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

  def determine_address(email, reference)
    overrider.destination_address(email.address).tap do |address|
      next if address == email.address
      Rails.logger.info(<<-INFO.strip_heredoc)
        Overriding email address #{email.address} to #{address}
        For email with reference: #{reference}
      INFO
    end
  end

  class EmailAddressOverrider
    attr_reader :override_address, :whitelist_addresses

    def initialize(config)
      @override_address = config[:email_address_override]
      @whitelist_addresses = Array(config[:email_address_override_whitelist])
    end

    def destination_address(address)
      return address unless override_address

      whitelist_addresses.include?(address) ? address : override_address
    end
  end
end
