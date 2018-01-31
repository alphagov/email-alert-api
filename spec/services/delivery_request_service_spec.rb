RSpec.describe DeliveryRequestService do
  let(:config) { EmailAlertAPI.config.email_service }

  describe "#provider_name" do
    it "defaults to 'pseudo'" do
      expect(subject.provider_name).to eq("pseudo")
    end

    it "downcases the provider from the config" do
      subject = described_class.new(config: config.merge(provider: "NOTIFY"))
      expect(subject.provider_name).to eq("notify")
    end
  end

  describe "#provider" do
    it "defaults to the PseudoProvider" do
      expect(subject.provider).to eq(PseudoProvider)
    end

    it "can be configured" do
      subject = described_class.new(config: config.merge(provider: "NOTIFY"))
      expect(subject.provider).to eq(NotifyProvider)
    end
  end

  describe "#subject_prefix" do
    it "defaults to nil" do
      expect(subject.subject_prefix).to eq(nil)
    end

    it "can be configured" do
      subject = described_class.new(config: config.merge(email_subject_prefix: "STAGING - "))
      expect(subject.subject_prefix).to eq("STAGING - ")
    end
  end

  describe "#call" do
    let!(:email) { create(:email) }

    around do |example|
      Timecop.freeze(2017, 1, 1) { example.run }
    end

    it "calls the provider" do
      expect(subject.provider).to receive(:call).with(
        hash_including(
          address: "test@example.com",
          subject: "subject",
          body: "body",
        )
      )

      subject.call(email: email)
    end

    context "when the email address is overridden" do
      let(:subject) do
        described_class.new(config: config.merge(email_address_override: address))
      end

      let(:address) { "overridden@example.com" }

      it "calls the provider with the overridden email address" do
        expect(subject.provider).to receive(:call)
          .with(hash_including(address: address))

        subject.call(email: email)
      end
    end

    it "prefixes the subject if configured to do so" do
      subject = described_class.new(config: config.merge(email_subject_prefix: "STAGING - "))
      expect(subject.subject_prefix).to eq("STAGING - ")

      expect(subject.provider).to receive(:call).with(
        hash_including(
          subject: "STAGING - subject",
        )
      )

      subject.call(email: email)
    end

    it "sets the reference to something that might make debugging easier" do
      expected = "delivery-attempt-for-email-#{email.id}-sent-to-notify-at-2017-01-01T00:00:00+00:00"

      expect(subject.provider).to receive(:call).with(->(params) {
        expect(params.fetch(:reference)).to eq(expected)
      })

      subject.call(email: email)
    end

    it "creates a delivery attempt" do
      expect { subject.call(email: email) }
        .to change(DeliveryAttempt, :count).by(1)
    end

    it "associates the delivery attempt with the email" do
      subject.call(email: email)
      expect(DeliveryAttempt.last.email).to eq(email)
    end

    it "sets the delivery attempt's status to sending" do
      subject.call(email: email)
      expect(DeliveryAttempt.last).to be_sending
    end

    it "sets the delivery attempt's provider to the name of the provider" do
      subject.call(email: email)
      expect(DeliveryAttempt.last.provider).to eq("pseudo")
    end

    it "sets the reference to same string that was sent the provider" do
      reference = nil
      expect(subject.provider).to receive(:call).with(->(params) {
        reference = params.fetch(:reference)
      })

      subject.call(email: email)

      expect(reference).to be_present
      expect(DeliveryAttempt.last.reference).to eq(reference)
    end

    context "when the provider errors" do
      before do
        allow(subject.provider).to receive(:call).and_raise(ProviderError)
      end

      it "sets the delivery attempt's status to technical_failure" do
        subject.call(email: email)
        expect(DeliveryAttempt.last).to be_technical_failure
      end
    end

    it "records a metric for the delivery attempt" do
      expect(MetricsService).to receive(:first_delivery_attempt)
        .with(email, Time.now.utc)

      subject.call(email: email)
    end

    it "records a metric for the request to the provdier" do
      expect(MetricsService).to receive(:email_send_request)
        .with("pseudo")

      subject.call(email: email)
    end
  end

  describe described_class::EmailAddressOverrider do
    let(:config) { EmailAlertAPI.config.email_service }
    subject { described_class.new(config) }

    describe "#email_address_override" do
      it "defaults to nil" do
        expect(subject.email_address_override).to eq(nil)
      end

      it "can be configured" do
        address = "overriden@example.com"
        subject = described_class.new(config.merge(email_address_override: address))

        expect(subject.email_address_override).to eq(address)
      end
    end

    describe "#address" do
      let(:email) { create(:email, address: "original@example.com") }

      context "when an override address is set" do
        let(:config) { { email_address_override: "overriden@example.com" } }

        it "returns the overridden address" do
          result = subject.address(email, "subject", "reference")
          expect(result).to eq("overriden@example.com")
        end

        it "logs the original and overriden email addresses" do
          expect(Rails.logger).to receive(:info).with(->(string) {
            expect(string).to include("Sending email to original@example.com")
            expect(string).to include("overridden to overriden@example.com")
          })

          subject.address(email, "subject", "reference")
        end

        it "logs the subject, reference and email body" do
          expect(Rails.logger).to receive(:info).with(->(string) {
            expect(string).to include("Subject: STAGING - subject")
            expect(string).to include("Reference: ref-123")
            expect(string).to include("Body: body")
          })

          subject.address(email, "STAGING - subject", "ref-123")
        end
      end

      context "when an override address is not set" do
        it "returns the original address" do
          result = subject.address(email, "subject", "reference")
          expect(result).to eq("original@example.com")
        end

        it "does not log" do
          expect(Rails.logger).not_to receive(:info)
          subject.address(email, "subject", "reference")
        end
      end
    end
  end
end
