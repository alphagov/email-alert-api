require "notifications/client"

module EmailSender
  class Notify
    def call(address:, subject:, body:)
      begin
        client.send_email(
          email_address: address,
          template_id: template_id,
          personalisation: {
            subject: subject,
            body: body,
          },
        )
      rescue Notifications::Client::RequestError => ex
        raise unless ex.code.to_s == "429"
      end
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
