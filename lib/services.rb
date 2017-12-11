require "gov_delivery/client"
require "gds_api/content_store"
require "notifications/client"

module Services
  def self.gov_delivery
    @gov_delivery ||= GovDelivery::Client.new(EmailAlertAPI.config.gov_delivery)
  end

  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.new.find("content-store"))
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

  def self.rate_limiter
    default_rate_for_six_workers = 8

    @rate_limiter ||= RateSleeperService.new(
      jobs_per_second: ENV.fetch(
        "GOVUK_NOTIFY_RATE_PER_WORKER",
        default_rate_for_six_workers
      )
    )
  end
end
