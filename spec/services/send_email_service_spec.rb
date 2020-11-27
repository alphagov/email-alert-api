RSpec.describe SendEmailService do
  describe ".call" do
    let(:email) { create(:email) }
    let(:default_provider_name) { "pseudo" }
    let(:default_provider) { SendEmailService::PseudoProvider }
    let(:email_service_config) { EmailAlertAPI.config.email_service }

    it "calls the provider to send an email" do
      email_parameters = { address: email.address,
                           subject: email.subject,
                           body: email.body,
                           reference: email.id }
      expect(default_provider).to receive(:call)
                              .with(hash_including(email_parameters))
                              .and_return(:sent)
      described_class.call(email: email)
    end

    it "can send an email to a configured provider" do
      allow(EmailAlertAPI.config)
        .to receive(:email_service)
        .and_return(email_service_config.merge(provider: "NOTIFY"))

      expect(SendEmailService::NotifyProvider).to receive(:call).and_return(:sent)
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

    it "marks an email as sent when the provider returns a sent status" do
      allow(default_provider).to receive(:call).and_return(:sent)

      freeze_time do
        expect { described_class.call(email: email) }
          .to change { email.status }.to("sent")
          .and change { email.sent_at }.to(Time.zone.now)
      end
    end

    it "marks an email as sent when the provider returns a delivered status" do
      allow(default_provider).to receive(:call).and_return(:delivered)

      freeze_time do
        expect { described_class.call(email: email) }
          .to change { email.status }.to("sent")
          .and change { email.sent_at }.to(Time.zone.now)
      end
    end

    it "marks an email as failed when the provider returns a undeliverable_failure status" do
      allow(default_provider).to receive(:call).and_return(:undeliverable_failure)

      expect { described_class.call(email: email) }
        .to change { email.status }.to("failed")
    end

    it "raises a ProviderCommunicationFailureError when then provider returns a " \
      "provider_communication_failure status" do
      allow(default_provider).to receive(:call).and_return(:provider_communication_failure)

      expect { described_class.call(email: email) }
        .to raise_error(described_class::ProviderCommunicationFailureError)
    end

    it "raises a ProviderCommunicationFailureError when then provider raises an error" do
      allow(default_provider).to receive(:call).and_raise("boom")

      expect { described_class.call(email: email) }
        .to raise_error(described_class::ProviderCommunicationFailureError)
    end

    it "can record content change creation metrics when these are provided" do
      freeze_time do
        content_change_created_at = 1.hour.ago
        metrics = { content_change_created_at: content_change_created_at }
        expect(Metrics)
          .to receive(:content_change_created_until_email_sent)
          .with(content_change_created_at, Time.zone.now)

        described_class.call(email: email, metrics: metrics)
      end
    end
  end
end
