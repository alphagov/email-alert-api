require "notifications/client"

class EmailSenderService
  class Notify
    def call(address:, subject:, body:)
      response = client.send_email(
        email_address: address,
        template_id: template_id,
        personalisation: {
          subject: subject,
          body: body,
        },
      )
      EmailAlertAPI.statsd.increment("notify.email_send_request.success")
      response.id
    rescue Notifications::Client::RequestError
      EmailAlertAPI.statsd.increment("notify.email_send_request.failure")
      raise EmailSenderService::ClientError
    end

  private

    def client
      @client ||= Notifications::Client.new(api_key)
    end

    def config
      EmailAlertAPI.config.notify
    end

    def api_key
      config.fetch(:api_key)
    end

    def template_id
      config.fetch(:template_id)
    end
  end
end
