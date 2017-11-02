require "rails_helper"
require "notifications/client"

RSpec.describe DeliverToSubscriber do
  context "when sending through Notify" do
    let(:email_sender) { EmailSenderService::EmailSender.clone }

    describe ".call" do
      it "makes a call to Notify to send an email" do
        subscriber = create(:subscriber, address: "test@test.com")
        email = create(:email)
        client = Notifications::Client.new("key")
        allow(Notifications::Client).to receive(:new).and_return(client)

        expect(Services).to receive(:email_sender).and_return(email_sender.new)

        expect(client).to receive(:send_email).with(
          hash_including(email_address: "test@test.com")
        )

        allow(EmailAlertAPI.config).to receive(:email_service).and_return(provider: "NOTIFY", email_address_override: nil)

        DeliverToSubscriber.call(subscriber: subscriber, email: email)
      end
    end
  end

  context "when sending through Pseudo" do
    let(:email_sender) { EmailSenderService::EmailSender.clone }

    describe ".call" do
      it "should send an info message to the logger" do
        subscriber = create(:subscriber, address: "test@test.com")
        email = create(:email)
        fake_log = double

        allow(EmailAlertAPI.config).to receive(:email_service).and_return(provider: "PSEUDO", email_address_override: nil)

        expect(Services).to receive(:email_sender).and_return(email_sender.new)

        allow(Logger)
          .to receive(:new)
          .with("#{Rails.root}/log/pseudo_email.log", 5, 4194304)
          .and_return(fake_log)

        expect(fake_log)
          .to receive(:info)
          .with("Sending email to test@test.com\nSubject: subject\nBody: body\n")

        DeliverToSubscriber.call(subscriber: subscriber, email: email)
      end
    end
  end
end
