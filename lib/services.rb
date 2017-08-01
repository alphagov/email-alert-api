require "gov_delivery/client"
require 'gds_api/content_store'
require 'gds_api/gov_uk_delivery'

module Services
  def self.gov_delivery
    @gov_delivery ||= GovDelivery::Client.new(EmailAlertAPI.config.gov_delivery)
  end

  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.new.find('content-store'))
  end

  def self.govuk_delivery
    @govuk_delivery ||= GdsApi::GovUkDelivery.new(Plek.new.find('govuk-delivery'))
  end
end
