require "rails_helper"
require "notifications/client"

RSpec.describe DeliverToSubscriber do
  context "when sending through Notify" do
    before(:example) do
      expect(Services)
        .to receive(:email_sender)
        .and_return(EmailSender::Notify.new)
    end

    describe ".call" do
      it "makes a call to Notify to send an email" do
        subscriber = create(:subscriber, address: "test@test.com")
        email = create(:email)
        client = Notifications::Client.new("key")
        allow(Notifications::Client).to receive(:new).and_return(client)

        expect(client).to receive(:send_email).with(
          hash_including(email_address: "test@test.com")
        )

        DeliverToSubscriber.call(subscriber: subscriber, email: email)
      end
    end
  end

  context "when sending through Pseudo" do
    describe ".call" do
      it "should send an info message to the logger" do
        subscriber = create(:subscriber, address: "test@test.com")
        email = create(:email)
        fake_log = double

        allow(Logger)
          .to receive(:new)
          .with("#{Rails.root}/log/pseudo_email.log")
          .and_return(fake_log)

        expect(fake_log)
          .to receive(:info)
          .with("Sending email to test@test.com\nSubject: subject\nBody: body\n")

        DeliverToSubscriber.call(subscriber: subscriber, email: email)
      end
    end
  end
end
