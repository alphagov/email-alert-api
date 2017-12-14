require "gov_delivery/client"

module Services
  def self.gov_delivery
    @gov_delivery ||= GovDelivery::Client.new(EmailAlertAPI.config.gov_delivery)
  end

  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.new.find("content-store"))
  end

  def self.notify
    NotifyProvider.new.client
  end

  def self.rate_limiter
    @rate_limiter ||= Ratelimit.new("deliveries")
  end
end
