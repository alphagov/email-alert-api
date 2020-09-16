class DeliveryRequestService::NotifyProvider
  def initialize
    @client = EmailAlertAPI.config.notify_client
    @template_id = EmailAlertAPI.config.notify.fetch(:template_id)
  end

  def self.call(*args)
    new.call(*args)
  end

  def call(address:, subject:, body:, reference:)
    client.send_email(
      email_address: address,
      template_id: template_id,
      reference: reference,
      personalisation: {
        subject: subject,
        body: body,
      },
    )

    Metrics.sent_to_notify_successfully
    :sent
  rescue Notifications::Client::RequestError, Net::OpenTimeout => e
    Metrics.failed_to_send_to_notify

    Rails.logger.warn(
      "Notify communication failure for reference #{reference}. #{e.class}: #{e}",
    )

    undeliverable_failure?(e) ? :undeliverable_failure : :provider_communication_failure
  end

private

  attr_reader :client, :template_id

  def undeliverable_failure?(error)
    return false unless error.is_a?(Notifications::Client::BadRequestError)

    error.message.end_with?("Not a valid email address")
  end
end
