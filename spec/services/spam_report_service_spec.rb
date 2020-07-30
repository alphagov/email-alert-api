RSpec.describe SpamReportService do
  describe ".call" do
    let(:subscription) { create(:subscription) }
    let(:subscriber) { subscription.subscriber }
    let(:email) { create(:email, subscriber_id: subscriber.id) }
    let!(:delivery_attempt) { create(:delivery_attempt, email_id: email.id) }

    context "when the delivery attempt can be found" do
      it "delegates to the UnsubscribeService" do
        expect(UnsubscribeService).to receive(:call)
          .with(subscriber, [subscription], :marked_as_spam)

        described_class.call(delivery_attempt.id, subscriber.address)
      end

      it "marks the email as spam" do
        described_class.call(delivery_attempt.id, subscriber.address)
        expect(email.reload).to be_marked_as_spam
      end
    end

    context "when the delivery attempt cannot be found" do
      it "delegates to UnsubscribeAllService" do
        allow(DeliveryAttempt).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        expect(UnsubscribeService).to receive(:call)
          .with(subscriber, [subscription], :marked_as_spam)

        described_class.call(delivery_attempt.id, subscriber.address)
      end

      it "sends stats that an email has been marked as spam" do
        allow(DeliveryAttempt).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        expect(Metrics).to receive(:marked_as_spam)
        described_class.call(delivery_attempt.id, subscriber.address)
      end
    end

    context "when an email is not already marked as spam" do
      it "sends stats about the email marked as spam" do
        expect(Metrics).to receive(:marked_as_spam)
        described_class.call(delivery_attempt.id, subscriber.address)
      end
    end

    context "when an email is already marked as spam" do
      it "does not send stats about the email marked as spam" do
        email = create(:email, subscriber_id: subscriber.id, marked_as_spam: true)
        delivery_attempt = create(:delivery_attempt, email_id: email.id)
        expect(Metrics).not_to receive(:marked_as_spam)
        described_class.call(delivery_attempt.id, subscriber.address)
      end
    end
  end
end
