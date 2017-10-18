require "notifications/client"

module EmailSender
  class Notify
    def call(address:, **keyword_args)
      send_to_notify(address: address, **keyword_args)
    end

  private

    def send_to_notify(address:, **keyword_args)
      client.send_email(
        email_address: address,
        template_id: template_id(keyword_args)
      )
    end

    def client
      @client ||= Notifications::Client.new(notify_api_key)
    end

    def notify_config
      EmailAlertAPI.config.notify
    end

    def notify_api_key
      notify_config.fetch(:api_key)
    end

    def template_id(template_id: nil, **_)
      template_id || notify_config.fetch(:template_id)
    end
  end
end
