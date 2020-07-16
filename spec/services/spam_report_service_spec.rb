RSpec.describe SpamReportService do
  describe ".call" do
    let(:subscription) { create(:subscription) }
    let(:subscriber) { subscription.subscriber }
    let(:email) { create(:email, subscriber_id: subscriber.id) }
    let(:delivery_attempt) { create(:delivery_attempt, email: email) }

    it "delegates to the UnsubscribeService" do
      expect(UnsubscribeService).to receive(:unsubscribe!)
        .with(subscriber, [subscription], :marked_as_spam)

      described_class.call(delivery_attempt)
    end

    it "marks the email as spam" do
      described_class.call(delivery_attempt)
      expect(email.marked_as_spam).to be_truthy
    end
  end
end
