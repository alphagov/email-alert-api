class DeliveryRequestService < ApplicationService
  class ProviderCommunicationFailureError < RuntimeError; end

  PROVIDERS = {
    "notify" => NotifyProvider,
    "pseudo" => PseudoProvider,
    "delay" => DelayProvider,
  }.freeze

  def initialize(email:, metrics: {})
    config = EmailAlertAPI.config.email_service
    @email = email
    @metrics = metrics
    @provider_name = config.fetch(:provider).downcase
    @subject_prefix = config.fetch(:email_subject_prefix)
    @overrider = EmailAddressOverrider.new(config)
  end

  def call
    return if address.nil?

    status = Metrics.email_send_request(provider_name) { send_email }

    case status
    when :sent
      email.update!(status: :sent, sent_at: Time.zone.now)
    when :delivered
      email.update!(status: :sent, sent_at: Time.zone.now)
    when :undeliverable_failure
      email.update!(status: :failed)
    when :provider_communication_failure
      raise ProviderCommunicationFailureError
    end

    record_sent_metrics
  end

private

  attr_reader :email, :metrics, :provider_name, :subject_prefix, :overrider

  def address
    @address ||= overrider.destination_address(email.address)
  end

  def send_email
    provider = PROVIDERS.fetch(provider_name)

    provider.call(
      address: address,
      subject: subject_prefix + email.subject,
      body: email.body,
      reference: email.id,
    )
  rescue StandardError => e
    GovukError.notify(e)
    raise ProviderCommunicationFailureError
  end

  def record_sent_metrics
    return unless email.sent_at
    return unless metrics[:content_change_created_at]

    Metrics.content_change_created_until_email_sent(
      metrics[:content_change_created_at],
      email.sent_at,
    )
  end
end
