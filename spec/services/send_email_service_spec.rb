RSpec.describe SendEmailService do
  describe ".call" do
    context "when GOVUK_NOTIFY_RECIPIENTS is configured to *" do
      around do |example|
        ClimateControl.modify(GOVUK_NOTIFY_RECIPIENTS: "*") { example.run }
      end

      it "delegates sending emails to SendNotifyEmail" do
        email = create(:email)
        expect(described_class::SendNotifyEmail).to receive(:call).with(email)
        described_class.call(email:)
      end
    end

    context "when GOVUK_NOTIFY_RECIPIENTS is configured to specific email addresses" do
      around do |example|
        recipients = "person-1@example.com,person-2@example.com"
        ClimateControl.modify(GOVUK_NOTIFY_RECIPIENTS: recipients) do
          example.run
        end
      end

      it "delegates sending configured emails to SendNotifyEmail" do
        email = create(:email, address: "person-2@example.com")
        expect(described_class::SendNotifyEmail).to receive(:call).with(email)
        described_class.call(email:)
      end

      it "delegates those not configured to be sent via SendPseudoEmail" do
        email = create(:email, address: "person-3@example.com")
        expect(described_class::SendPseudoEmail).to receive(:call).with(email)
        described_class.call(email:)
      end
    end

    context "when GOVUK_NOTIFY_RECIPIENTS is not set" do
      around do |example|
        ClimateControl.modify(GOVUK_NOTIFY_RECIPIENTS: nil) { example.run }
      end

      it "delegates sending emails to SendPseudoEmail" do
        email = create(:email)
        expect(described_class::SendPseudoEmail).to receive(:call).with(email)
        described_class.call(email:)
      end
    end

    it "can record content change creation metrics" do
      freeze_time do
        content_change_created_at = 1.hour.ago
        metrics = { content_change_created_at: }
        expect(Metrics)
          .to receive(:content_change_created_until_email_sent)
          .with(content_change_created_at, Time.zone.now)

        described_class.call(email: create(:email), metrics:)
      end
    end
  end
end
