class NotifyProvider
  def initialize(config: EmailAlertAPI.config.notify, notify_client: EmailAlertAPI.config.notify_client)
    @client = notify_client
    @template_id = config.fetch(:template_id)
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

    MetricsService.sent_to_notify_successfully
    :sending
  rescue StandardError => e
    MetricsService.failed_to_send_to_notify
    GovukError.notify(e, tags: { provider: "notify" })
    :technical_failure
  end

private

  attr_reader :client, :template_id
end
