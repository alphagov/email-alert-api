RSpec.describe SpamReportService do
  describe ".call" do
    let(:subscription) { create(:subscription) }
    let(:subscriber) { subscription.subscriber }
    let(:email) { create(:email, subscriber_id: subscriber.id) }

    it "delegates to the UnsubscribeService" do
      expect(UnsubscribeService).to receive(:call)
        .with(subscriber, [subscription], :marked_as_spam)

      described_class.call(email)
    end

    it "marks the email as spam" do
      described_class.call(email)
      expect(email.marked_as_spam).to be_truthy
    end

    context "when an email is not already marked as spam" do
      it "sends stats about the email marked as spam" do
        expect(Metrics).to receive(:marked_as_spam)
        described_class.call(email)
      end
    end

    context "when an email is already marked as spam" do
      it "does not send stats about the email marked as spam" do
        email = create(:email, subscriber_id: subscriber.id, marked_as_spam: true)
        expect(Metrics).not_to receive(:marked_as_spam)
        described_class.call(email)
      end
    end
  end
end
