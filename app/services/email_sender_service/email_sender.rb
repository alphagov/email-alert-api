module EmailSenderService
  class EmailSender
    def call(address:, subject:, body:)
      provider.call(
        address: email_or_email_override(address),
        subject: subject,
        body: body
      )
    end

  private

    def config
      EmailAlertAPI.config.email_service
    end

    def email_override
      config[:email_address_override]
    end

    def configured_service_provider
      config.fetch(:provider)
    end

    def email_or_email_override(address)
      return email_override if email_override.present?
      address
    end

    def use_notify_provider?
      configured_service_provider == "NOTIFY"
    end

    def use_pseudo_provider?
      configured_service_provider == "PSEUDO" ||
        configured_service_provider.nil?
    end

    def provider
      return @provider ||= Notify.new if use_notify_provider?
      return @provider ||= Pseudo.new if use_pseudo_provider?
      raise "Email service provider #{configured_service_provider} does not exist"
    end
  end
end
