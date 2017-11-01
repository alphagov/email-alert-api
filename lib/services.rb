require "gov_delivery/client"
require 'gds_api/content_store'
require "email_sender_service/notify"
require "email_sender_service/pseudo"

module Services
  def self.gov_delivery
    @gov_delivery ||= GovDelivery::Client.new(EmailAlertAPI.config.gov_delivery)
  end

  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.new.find('content-store'))
  end

  def self.email_sender
    @email_sender ||= EmailSenderService::EmailSender.new
  end
end
