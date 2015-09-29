require "gov_delivery/client"

module Services
  def self.gov_delivery
    @gov_delivery ||= GovDelivery::Client.new(EmailAlertAPI.config.gov_delivery)
  end
end
