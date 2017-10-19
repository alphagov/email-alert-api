require "rails_helper"

RSpec.describe DeliverToSubscriber do
  describe ".call" do
    let(:email_sender) { double }
    before do
      allow(Services).to receive(:email_sender).and_return(
        email_sender
      )
    end

    it "calls email_sender with address" do
      subscriber = double(address: "test@test.com")

      expect(email_sender).to receive(:call)
        .with(address: "test@test.com")

      DeliverToSubscriber.call(
        subscriber: subscriber,
      )
    end

    it "requires subscriber" do
      expect {
        DeliverToSubscriber.call(subscriber: nil)
      }.to raise_error(
        ArgumentError,
        "subscriber cannot be nil"
      )
    end
  end
end
