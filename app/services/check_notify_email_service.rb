class CheckNotifyEmailService
  def initialize(status)
    @status = status
    @client = Notifications::Client.new(Rails.application.credentials.notify_api_key)
  end

  def present?(reference)
    results = @client.get_notifications(
      template_type: "email",
      status: @status,
      reference:,
    )

    results.collection.count.positive?
  rescue Notifications::Client::RequestError, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Rails.logger.debug("Unable to contact Notify to determine status of email reference #{reference}: #{e}")
  end
end
