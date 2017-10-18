require "rails_helper"
require "notifications/client"

RSpec.describe DeliverToSubscriber do
  describe ".call" do
    it "makes a call to Notify to send an email" do
      subscriber = create(:subscriber, address: "test@test.com")
      client = Notifications::Client.new("key")
      allow(Notifications::Client).to receive(:new).and_return(client)

      expect(client).to receive(:send_email).with(
        hash_including(email_address: "test@test.com")
      )

      DeliverToSubscriber.call(subscriber: subscriber)
    end
  end
end
