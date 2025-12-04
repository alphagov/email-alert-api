class SendEmailService
  include Callable

  class NotifyCommunicationFailure < RuntimeError; end

  def initialize(email:, metrics: {})
    @email = email
    @metrics = metrics
  end

  def call
    if send_to_notify?
      Metrics.email_send_request("notify")
      SendNotifyEmail.call(email)
    else
      Metrics.email_send_request("pseudo")
      SendPseudoEmail.call(email)
    end

    record_sent_metrics
  end

private

  attr_reader :email, :metrics

  def send_to_notify?
    return true if ENV["GOVUK_NOTIFY_RECIPIENTS"] == "*"

    notify_recipients = ENV.fetch("GOVUK_NOTIFY_RECIPIENTS", "").split(",").map(&:strip)
    notify_recipients.include?(email.address)
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
