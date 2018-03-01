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
    reference = SecureRandom.uuid

    address = determine_address(email, reference)
    return if address.nil?

    delivery_attempt = create_delivery_attempt(email, reference)

    MetricsService.email_send_request(provider_name) do
      status = provider.call(
        address: address,
        subject: subject_prefix + email.subject,
        body: email.body,
        reference: reference,
      )

      ActiveRecord::Base.transaction do
        delivery_attempt.update!(status: status) if status != :sending

        email.finish_sending(delivery_attempt) if delivery_attempt.has_final_status?
      end
    end
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

  def create_delivery_attempt(email, reference)
    MetricsService.first_delivery_attempt(email, Time.now.utc)

    DeliveryAttempt.create!(
      id: reference,
      email: email,
      status: :sending,
      provider: provider_name,
      reference: reference,
    )
  end

  class EmailAddressOverrider
    attr_reader :override_address, :whitelist_addresses, :whitelist_only

    def initialize(config)
      @override_address = config[:email_address_override]
      @whitelist_addresses = Array(config[:email_address_override_whitelist])
      @whitelist_only = config[:email_address_override_whitelist_only]
    end

    def destination_address(address)
      return address unless override_address

      if whitelist_addresses.include?(address)
        address
      else
        whitelist_only ? nil : override_address
      end
    end
  end
end
