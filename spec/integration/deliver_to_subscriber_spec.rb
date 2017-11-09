require "rails_helper"
require "notifications/client"
require "app/services/email_sender/email_sender_service"
require "app/services/email_sender/notify"
require "app/services/email_sender/pseudo"

RSpec.describe DeliverEmail do
  let(:email_sender) { EmailSenderService.clone }
  let(:email) { create(:email, address: "test@test.com") }

  context "when sending through Notify" do
    describe ".call" do
      it "makes a call to Notify to send an email" do
        client = Notifications::Client.new("key")
        allow(Notifications::Client).to receive(:new).and_return(client)

        config = { provider: "NOTIFY", email_address_override: nil }
        expect(Services)
          .to receive(:email_sender)
          .and_return(email_sender.new(config, EmailSenderService::Notify.new))

        expect(client).to receive(:send_email).with(
          hash_including(email_address: "test@test.com")
        )

        DeliverEmail.call(email: email)
      end
    end
  end

  context "when sending through Pseudo" do
    describe ".call" do
      it "should send an info message to the logger" do
        fake_log = double

        config = { provider: "PSEUDO", email_address_override: nil }
        expect(Services)
          .to receive(:email_sender)
          .and_return(email_sender.new(config, EmailSenderService::Pseudo.new))

        allow(Logger)
          .to receive(:new)
          .with("#{Rails.root}/log/pseudo_email.log", 5, 4194304)
          .and_return(fake_log)

        expect(fake_log)
          .to receive(:info)
          .with("Sending email to test@test.com\nSubject: subject\nBody: body\n")

        DeliverEmail.call(email: email)
      end
    end
  end
end
