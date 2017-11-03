require "rails_helper"
require "notifications/client"
require "app/services/email_sender/email_sender_service"

RSpec.describe EmailSenderService do
  it "raises an error if the configured service provider is not supported" do
    config = { provider: "NOTSUPPORTED", email_override: nil }

    expect { EmailSenderService.new(config) }
      .to raise_error(RuntimeError, "Email service provider NOTSUPPORTED does not exist")
  end

  it "sends to the override email address" do
    config = { provider: "NOTIFY", email_override: "override@example.com" }

    email_sender = EmailSenderService.new(config)

    notify_client = Notifications::Client.new("key")
    allow(Notifications::Client).to receive(:new).and_return(notify_client)

    expect(notify_client).to receive(:send_email).with(
      hash_including(email_address: "override@example.com")
    )
    email_sender.call(address: "test@test.com", subject: "subject", body: "body")
  end
end
