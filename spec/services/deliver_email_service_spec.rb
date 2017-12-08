RSpec.describe DeliverEmailService do
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

      described_class.call(email: email)
    end

    it "creates a delivery attempt instance" do
      expect(email_sender).to receive(:call)
        .and_return(double(id: 0))

      described_class.call(email: email)

      expect(DeliveryAttempt.count).to eq(1)
    end

    it "requires email" do
      expect { described_class.call(email: nil) }
        .to raise_error(ArgumentError, "email cannot be nil")
    end

    context "in other environments" do
      after do
        ENV["GOVUK_APP_DOMAIN"] = nil
      end

      it "prefixes INTEGRATION when in integration" do
        ENV["GOVUK_APP_DOMAIN"] = "integration.publishing.service.gov.uk"
        expect(email_sender).to receive(:call)
          .with(
            address: "test@example.com",
            subject: "INTEGRATION - subject",
            body: "body",
        )
          .and_return(double(id: 0))

        described_class.call(email: email)
      end

      it "prefixes STAGING when in staging" do
        ENV["GOVUK_APP_DOMAIN"] = "staging.publishing.service.gov.uk"
        expect(email_sender).to receive(:call)
          .with(
            address: "test@example.com",
            subject: "STAGING - subject",
            body: "body",
        )
          .and_return(double(id: 0))

        described_class.call(email: email)
      end
    end
  end
end
