RSpec.describe DeliveryRequestService do
  describe ".call" do
    let(:email) { create(:email) }
    let(:default_provider_name) { "pseudo" }
    let(:default_provider) { DeliveryRequestService::PseudoProvider }
    let(:email_service_config) { EmailAlertAPI.config.email_service }

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
                              .and_return(:sent)
      described_class.call(email: email)
    end

    it "can send an email to a configured provider" do
      allow(EmailAlertAPI.config)
        .to receive(:email_service)
        .and_return(email_service_config.merge(provider: "NOTIFY"))

      expect(DeliveryRequestService::NotifyProvider).to receive(:call).and_return(:sent)
      described_class.call(email: email)
    end

    it "can prefix the subject with a configured prefix" do
      allow(EmailAlertAPI.config)
        .to receive(:email_service)
        .and_return(email_service_config.merge(email_subject_prefix: "[TEST] "))

      expect(default_provider).to receive(:call)
                              .with(hash_including(subject: "[TEST] #{email.subject}"))
                              .and_return(:sent)
      described_class.call(email: email)
    end

    it "can be configured to override a recepients email address" do
      address = "override@example.com"
      allow(EmailAlertAPI.config)
        .to receive(:email_service)
        .and_return(email_service_config.merge(email_address_override: address))

      expect(default_provider).to receive(:call)
                              .with(hash_including(address: address))
                              .and_return(:sent)
      described_class.call(email: email)
    end

    it "returns the delivery attempt when the overrider can provide an email address" do
      overrider_double = instance_double(
        described_class::EmailAddressOverrider,
        destination_address: "test@example.com",
      )
      allow(described_class::EmailAddressOverrider)
        .to receive(:new)
        .and_return(overrider_double)

      expect(described_class.call(email: email)).to be_a(DeliveryAttempt)
    end

    it "returns nil when no email was sent due to filtering" do
      overrider_double = instance_double(
        described_class::EmailAddressOverrider,
        destination_address: nil,
      )
      allow(described_class::EmailAddressOverrider)
        .to receive(:new)
        .and_return(overrider_double)

      expect(described_class.call(email: email)).to be_nil
    end

    context "when this is the first delivery attempt" do
      around { |example| freeze_time { example.run } }

      it "records the time of the delivery attempt" do
        expect(Metrics)
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
        expect(Metrics)
          .to receive(:content_change_created_to_first_delivery_attempt)
          .with(content_change_created_at, Time.zone.now)

        described_class.call(email: email, metrics: metrics)
      end
    end

    context "when this is not the first delivery attempt" do
      before { create(:delivery_attempt, email: email) }

      it "doesn't record the time of the delivery attempt" do
        expect(Metrics).not_to receive(:email_created_to_first_delivery_attempt)
        described_class.call(email: email)
      end
    end

    context "when sending the email returns a sent status" do
      it "marks the email as sent and sets the sent_at time" do
        allow(default_provider).to receive(:call).and_return(:sent)

        freeze_time do
          expect { described_class.call(email: email) }
            .to change { email.status }.to("sent")
            .and change { email.sent_at }.to(Time.zone.now)
        end
      end
    end

    context "when sending the email returns a delivered status" do
      before do
        allow(default_provider).to receive(:call).and_return(:delivered)
      end

      it "sets the delivery attempt status and completed time" do
        freeze_time do
          scope = DeliveryAttempt.where(status: :delivered,
                                        completed_at: Time.zone.now)
          expect { described_class.call(email: email) }
            .to change(scope, :count).by(1)
        end
      end

      it "marks the email as sent and sets the sent_at" do
        freeze_time do
          expect { described_class.call(email: email) }
            .to change { email.status }.to("sent")
            .and change { email.sent_at }.to(Time.zone.now)
        end
      end

      it "records that the delivery attempt status has changed" do
        expect(Metrics)
          .to receive(:delivery_attempt_status_changed)
          .with(:delivered)
        described_class.call(email: email)
      end
    end

    context "when sending the email returns a undeliverable_failure status" do
      before do
        allow(default_provider).to receive(:call).and_return(:undeliverable_failure)
      end

      it "sets the delivery attempt status and completed time" do
        freeze_time do
          scope = DeliveryAttempt.where(status: :undeliverable_failure,
                                        completed_at: Time.zone.now)
          expect { described_class.call(email: email) }
            .to change(scope, :count).by(1)
        end
      end

      it "marks the email as failed" do
        expect { described_class.call(email: email) }
          .to change { email.status }.to("failed")
      end

      it "records that the delivery attempt status has changed" do
        expect(Metrics)
          .to receive(:delivery_attempt_status_changed)
          .with(:undeliverable_failure)
        described_class.call(email: email)
      end
    end

    context "when sending the email raises an error" do
      before do
        allow(default_provider).to receive(:call).and_raise("Ut oh")
      end

      it "sets the delivery attempt status to provider_communication_failure" do
        scope = DeliveryAttempt.where(status: :provider_communication_failure)
        expect { described_class.call(email: email) }
          .to change(scope, :count).by(1)
      end

      it "records that the delivery attempt status has changed" do
        expect(Metrics)
          .to receive(:delivery_attempt_status_changed)
          .with(:provider_communication_failure)
        described_class.call(email: email)
      end
    end
  end
end
