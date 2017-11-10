require "rails_helper"

RSpec.describe DeliverEmail do
  describe ".call" do
    let(:email_sender) { double }
    before do
      allow(email_sender).to receive(:provider_name).and_return(:pseudo)

      allow(Services).to receive(:email_sender).and_return(
        email_sender
      )
    end

    let(:email) { create(:email) }

    it "calls email_sender with email" do
      expect(email_sender).to receive(:call)
        .with(
          address: "test@example.com",
          subject: "subject",
          body: "body",
        )
        .and_return(double(id: 0))

      DeliverEmail.call(email: email)
    end

    it "creates a delivery attempt instance" do
      expect(email_sender).to receive(:call)
        .and_return(double(id: 0))

      DeliverEmail.call(email: email)

      expect(DeliveryAttempt.count).to eq(1)
    end

    it "requires email" do
      expect {
        DeliverEmail.call(email: nil)
      }.to raise_error(
        ArgumentError,
        "email cannot be nil"
      )
    end
  end
end
