RSpec.describe SendEmailService::SendPseudoEmail do
  describe ".call" do
    let(:email) { create(:email) }

    it "writes the email details to the Rails log file" do
      expect(Rails.logger).to receive(:info).with(/Logging email/)
      described_class.call(email)
    end

    it "marks the email as sent" do
      freeze_time do
        expect { described_class.call(email) }
          .to change { email.reload.status }.to("sent")
          .and change { email.reload.sent_at }.to(Time.zone.now)
      end
    end
  end
end
