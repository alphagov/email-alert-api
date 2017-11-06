require "gov_delivery/client"
require 'gds_api/content_store'
require "email_sender/email_sender_service"
require "email_sender/notify"
require "email_sender/pseudo"

module Services
  def self.gov_delivery
    @gov_delivery ||= GovDelivery::Client.new(EmailAlertAPI.config.gov_delivery)
  end

  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.new.find('content-store'))
  end

  def self.email_sender
    @email_sender ||= EmailSenderService.new(EmailAlertAPI.config.email_service, email_provider)
  end

  def self.email_provider
    provider = EmailAlertAPI.config.email_service.fetch(:provider)
    return EmailSenderService::Notify.new if provider == "NOTIFY"
    return EmailSenderService::Pseudo.new if provider == "PSEUDO" || provider.nil?
    raise "Email service provider #{provider} does not exist"
  end
end
