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
    it "defaults to be an empty string" do
      expect(subject.subject_prefix).to eq("")
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

      it "logs the email address is overriden" do
        expect(Rails.logger).to receive(:info)
          .with(match(/Overriding email address/))
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

    describe "#destination_address" do
      subject(:destination_address) do
        described_class.new(config).destination_address(address)
      end

      context "when an override address is set" do
        let(:config) { { email_address_override: "overriden@example.com" } }
        let(:address) { "original@example.com" }

        it "returns the overridden address" do
          expect(destination_address).to eq("overriden@example.com")
        end
      end

      context "when an override address is not set" do
        let(:address) { "original@example.com" }

        it "returns the original address" do
          expect(destination_address).to eq("original@example.com")
        end
      end

      context "when an override address is set and whitelist addresses are set" do
        let(:config) do
          {
            email_address_override: "overriden@example.com",
            email_address_override_whitelist: ["whitelist@example.com"],
          }
        end

        context "when the argument is a whitelist address" do
          let(:address) { "whitelist@example.com" }

          it "returns the whitelisted address" do
            expect(destination_address).to eq("whitelist@example.com")
          end
        end

        context "when the argument is not a whitelist address" do
          let(:address) { "original@example.com" }

          it "returns the overriden address" do
            expect(destination_address).to eq("overriden@example.com")
          end
        end
      end

      context "when an override address is set and whitelist addresses are set and only whitelist emails should be sent" do
        let(:config) do
          {
            email_address_override: "overriden@example.com",
            email_address_override_whitelist: ["whitelist@example.com"],
            email_address_override_whitelist_only: true,
          }
        end

        context "when the argument is a whitelist address" do
          let(:address) { "whitelist@example.com" }

          it "returns the whitelisted address" do
            expect(destination_address).to eq("whitelist@example.com")
          end
        end

        context "when the argument is not a whitelist address" do
          let(:address) { "original@example.com" }

          it "returns a nil address" do
            expect(destination_address).to be_nil
          end
        end
      end

      context "when an override address is not set and whitelist addresses are set" do
        let(:config) do
          { email_address_override_whitelist: ["whitelist@example.com"] }
        end

        let(:address) { "original@example.com" }

        it "returns the original address" do
          expect(destination_address).to eq("original@example.com")
        end
      end
    end
  end
end
