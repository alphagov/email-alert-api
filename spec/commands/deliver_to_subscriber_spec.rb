require "rails_helper"

RSpec.describe DeliverToSubscriber do
  describe ".call" do
    let(:email_sender) { double }
    before do
      allow(Services).to receive(:email_sender).and_return(
        email_sender
      )
    end

    it "calls email_sender with email" do
      email = double(address: "test@test.com", subject: "test subject", body: "test body")

      expect(email_sender).to receive(:call)
        .with(
          address: "test@test.com",
          subject: "test subject",
          body: "test body",
        )

      DeliverToSubscriber.call(email: email)
    end

    it "requires email" do
      expect {
        DeliverToSubscriber.call(email: nil)
      }.to raise_error(
        ArgumentError,
        "email cannot be nil"
      )
    end
  end
end
