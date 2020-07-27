class NotifyProvider
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
    :sending
  rescue Notifications::Client::RequestError => e
    Metrics.failed_to_send_to_notify
    unless e.message.end_with?("Not a valid email address")
      GovukError.notify(e, tags: { provider: "notify" })
    end
    :technical_failure
  end

private

  attr_reader :client, :template_id
end
