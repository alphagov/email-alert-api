RSpec.describe DeliveryRequestService do
  let(:email) { create(:email) }
  let(:default_provider_name) { "pseudo" }
  let(:default_provider) { PseudoProvider }

  describe ".call" do
    it "creates a delivery attempt" do
      expect { described_class.call(email: email) }
        .to change { DeliveryAttempt.where(email: email).count }
        .by(1)
    end

    it "calls the provider to send an email" do
      email_parameters = { address: email.address,
                           subject: email.subject,
                           body: email.body }
      expect(default_provider).to receive(:call)
                              .with(hash_including(email_parameters))
                              .and_return(:sending)
      described_class.call(email: email)
    end

    it "can send an email to a configured provider" do
      config = EmailAlertAPI.config.email_service.merge(provider: "NOTIFY")
      expect(NotifyProvider).to receive(:call).and_return(:sending)
      described_class.call(email: email, config: config)
    end

    it "can prefix the subject with a configured prefix" do
      config = EmailAlertAPI.config.email_service.merge(email_subject_prefix: "[TEST] ")
      expect(default_provider).to receive(:call)
                              .with(hash_including(subject: "[TEST] #{email.subject}"))
                              .and_return(:sending)
      described_class.call(email: email, config: config)
    end

    it "can be configured to override a recepients email address" do
      address = "override@example.com"
      config = EmailAlertAPI.config.email_service.merge(email_address_override: address)
      expect(default_provider).to receive(:call)
                              .with(hash_including(address: address))
                              .and_return(:sending)
      described_class.call(email: email, config: config)
    end

    it "returns true when the overrider can provide an email address" do
      overrider_double = instance_double(
        described_class::EmailAddressOverrider,
        destination_address: "test@example.com",
      )
      allow(described_class::EmailAddressOverrider)
        .to receive(:new)
        .and_return(overrider_double)

      expect(described_class.call(email: email)).to be(true)
    end

    it "returns false when no email was sent due to filtering" do
      overrider_double = instance_double(
        described_class::EmailAddressOverrider,
        destination_address: nil,
      )
      allow(described_class::EmailAddressOverrider)
        .to receive(:new)
        .and_return(overrider_double)

      expect(described_class.call(email: email)).to be(false)
    end

    context "when this is the first delivery attempt" do
      around { |example| freeze_time { example.run } }

      it "records the time of the delivery attempt" do
        expect(MetricsService)
          .to receive(:email_created_to_first_delivery_attempt)
          .with(email.created_at, Time.zone.now)
        described_class.call(email: email)
      end
    end

    context "when this is the first delivery attempt and " \
            "content_change_created_at metrics are provided" do
      around { |example| freeze_time { example.run } }

      it "records the time from content change created until this delivery attempt" do
        content_change_created_at = 1.hour.ago
        metrics = { content_change_created_at: content_change_created_at }
        expect(MetricsService)
          .to receive(:content_change_created_to_first_delivery_attempt)
          .with(content_change_created_at, Time.zone.now)

        described_class.call(email: email, metrics: metrics)
      end
    end

    context "when this is not the first delivery attempt" do
      before { create(:delivery_attempt, email: email) }

      it "doesn't record the time of the delivery attempt" do
        expect(MetricsService).not_to receive(:email_created_to_first_delivery_attempt)
        described_class.call(email: email)
      end
    end

    context "when sending the email returns a sending status" do
      it "doesn't update the email status" do
        allow(default_provider).to receive(:call).and_return(:sending)
        expect(UpdateEmailStatusService).not_to receive(:call)
        described_class.call(email: email)
      end
    end

    context "when sending the email returns a non-sending status" do
      before do
        allow(default_provider).to receive(:call).and_return(:permanent_failure)
      end

      it "sets the delivery attempt status and completed time" do
        freeze_time do
          scope = DeliveryAttempt.where(status: :permanent_failure,
                                        completed_at: Time.zone.now)
          expect { described_class.call(email: email) }
            .to change(scope, :count).by(1)
        end
      end

      it "updates the email status" do
        expect(UpdateEmailStatusService).to receive(:call)
        described_class.call(email: email)
      end
    end

    context "when sending the email raises an error" do
      before do
        allow(default_provider).to receive(:call).and_raise("Ut oh")
      end

      it "sets the delivery attempt status to internal_failure" do
        scope = DeliveryAttempt.where(status: :internal_failure)
        expect { described_class.call(email: email) }
          .to change(scope, :count).by(1)
      end

      it "updates the email status" do
        expect(UpdateEmailStatusService).to receive(:call)
        described_class.call(email: email)
      end
    end
  end
end
