require "rails_helper"
require "notifications/client"

RSpec.describe EmailSender::NotifySender do
  describe "#call" do
    it "sends an email to the address passed in" do
      client = Notifications::Client.new("key")
      allow(Notifications::Client)
        .to receive(:new)
        .and_return(client)

      expect(client)
        .to receive(:send_email)
        .with(email_address: "email@address.com", template_id: anything())
        .and_return(Notifications::Client::ResponseNotification)

      Services.email_sender.call(address: "email@address.com")
    end

    it "returns false if the notify gem raises a Notifications::Client::RequestError" do
      client = Notifications::Client.new("key")
      allow(Notifications::Client)
        .to receive(:new)
        .and_return(client)

      allow(client)
        .to receive(:send_email)
        .and_raise(Notifications::Client::RequestError)

      expect(Services.email_sender)
        .to receive(:call)
        .and_return(false)

      Services.email_sender.call(address: "email@address.com")
    end
  end
end
