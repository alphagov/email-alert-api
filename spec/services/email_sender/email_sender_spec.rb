require "rails_helper"
require "notifications/client"
require "app/services/email_sender/email_sender_service"
require "app/services/email_sender/notify"

RSpec.describe EmailSenderService do
  it "raises an error if the configured service provider is not supported" do
    config = { provider: "NOTSUPPORTED", email_override: nil }

    expect { EmailSenderService.new(config) }
      .to raise_error(RuntimeError, "Email service provider NOTSUPPORTED does not exist")
  end
end
