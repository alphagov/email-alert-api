class DeliveryRequestService < ApplicationService
  PROVIDERS = {
    "notify" => NotifyProvider,
    "pseudo" => PseudoProvider,
    "delay" => DelayProvider,
  }.freeze

  def initialize(email:, metrics: {})
    config = EmailAlertAPI.config.email_service
    @email = email
    @metrics = metrics
    @attempt_id = SecureRandom.uuid
    @provider_name = config.fetch(:provider).downcase
    @subject_prefix = config.fetch(:email_subject_prefix)
    @overrider = EmailAddressOverrider.new(config)
  end

  def call
    return if address.nil?

    Metrics.delivery_request_service_first_delivery_attempt do
      record_first_attempt_metrics unless DeliveryAttempt.exists?(email: email)
    end

    attempt = Metrics.delivery_request_service_create_delivery_attempt do
      DeliveryAttempt.create!(id: attempt_id,
                              email: email,
                              status: :sent,
                              provider: provider_name)
    end

    status = Metrics.email_send_request(provider_name) { send_email }

    ActiveRecord::Base.transaction do
      case status
      when :sent
        email.update!(status: :sent, sent_at: Time.zone.now)
      when :delivered
        record_metric_and_update_attempt(attempt, status)
        email.update!(status: :sent, finished_sending_at: attempt.finished_sending_at, sent_at: Time.zone.now)
      when :undeliverable_failure
        record_metric_and_update_attempt(attempt, status)
        email.update!(status: :failed, finished_sending_at: attempt.finished_sending_at)
      when :provider_communication_failure
        record_metric_and_update_attempt(attempt, status)
      end
    end

    attempt
  end

private

  attr_reader :attempt_id, :email, :metrics, :provider_name, :subject_prefix, :overrider

  def address
    @address ||= overrider.destination_address(email.address)
  end

  def send_email
    provider = PROVIDERS.fetch(provider_name)

    provider.call(
      address: address,
      subject: subject_prefix + email.subject,
      body: email.body,
      reference: attempt_id,
    )
  rescue StandardError => e
    GovukError.notify(e)
    :provider_communication_failure
  end

  def record_first_attempt_metrics
    now = Time.zone.now.utc
    Metrics.email_created_to_first_delivery_attempt(email.created_at, now)

    return unless metrics[:content_change_created_at]

    Metrics.content_change_created_to_first_delivery_attempt(
      metrics[:content_change_created_at],
      now,
    )
  end

  def record_metric_and_update_attempt(attempt, status)
    Metrics.delivery_attempt_status_changed(status)
    attempt.update!(status: status, completed_at: Time.zone.now)
  end
end
