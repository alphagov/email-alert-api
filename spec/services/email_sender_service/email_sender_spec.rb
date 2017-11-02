require "rails_helper"
require "notifications/client"

RSpec.describe EmailSenderService::EmailSender do
  it "raises an error if the configured service provider is not supported" do
    allow(EmailAlertAPI.config).to receive(:email_service).and_return(provider: "NOTSUPPORTED", email_address_override: nil)

    email_sender = EmailSenderService::EmailSender.new

    expect { email_sender.call(address: "test@test.com", subject: "subject", body: "body") }
      .to raise_error(RuntimeError, "Email service provider NOTSUPPORTED does not exist")
  end
end
