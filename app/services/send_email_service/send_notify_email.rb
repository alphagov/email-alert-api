class SendEmailService::SendNotifyEmail
  def initialize(email)
    @email = email
    @client = Notifications::Client.new(Rails.application.secrets.notify_api_key)
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    client.send_email(
      email_address: email.address,
      template_id: Rails.application.config.notify_template_id,
      reference: email.id,
      personalisation: {
        subject: email.subject,
        body: email.body,
      },
    )

    Metrics.sent_to_notify_successfully
    email.update!(status: :sent, sent_at: Time.zone.now)
  rescue Notifications::Client::RequestError, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Metrics.failed_to_send_to_notify

    Rails.logger.warn(
      "Notify communication failure for reference #{email.id}. #{e.class}: #{e}",
    )

    if undeliverable_failure?(e)
      email.update!(status: :failed)
    else
      raise SendEmailService::NotifyCommunicationFailure
    end
  end

private

  attr_reader :email, :client

  def undeliverable_failure?(error)
    return false unless error.is_a?(Notifications::Client::BadRequestError)

    return true if error.message.end_with?("Not a valid email address")

    # We have a hard limit in notify that cannot be bypassed here.
    error.message.start_with?("BadRequestError: Your message is too long")
  end
end
