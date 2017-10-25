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
      email = double(subject: "test subject", body: "test body")

      expect(email_sender).to receive(:call)
        .with(
          address: "test@test.com",
          subject: "test subject",
          body: "test body",
        )

      DeliverToSubscriber.call(
        subscriber: subscriber,
        email: email,
      )
    end

    it "requires subscriber" do
      expect {
        DeliverToSubscriber.call(subscriber: nil, email: double)
      }.to raise_error(
        ArgumentError,
        "subscriber cannot be nil"
      )
    end

    it "requires email" do
      expect {
        DeliverToSubscriber.call(subscriber: double, email: nil)
      }.to raise_error(
        ArgumentError,
        "email cannot be nil"
      )
    end
  end
end
