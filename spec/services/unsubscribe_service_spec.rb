RSpec.describe UnsubscribeService do
  describe ".unsubscribe!" do
    let(:subscriber) { create(:subscriber, address: "foo@bar.com") }
    let(:subscriptions) { create_list(:subscription, 2, subscriber: subscriber) }

    it "ends the specified subscriptions" do
      described_class.unsubscribe!(subscriber, [subscriptions.first], :unsubscribed)
      expect(subscriber.active_subscriptions.count).to eq 1
    end

    context "when the email address is invalid" do
      before do
        allow(subscriber).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not remove the subscriptions" do
        expect { described_class.unsubscribe!(subscriber, subscriptions, :unsubscribed) }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(subscriber.active_subscriptions).to be_present
      end
    end

    context "when other subscriptions remain" do
      it "does not deactivate the subscriber" do
        described_class.unsubscribe!(subscriber, [subscriptions.first], :unsubscribed)
        expect(subscriber.reload.deactivated?).to be_falsey
      end
    end

    context "when all subscriptions are ended" do
      it "deactivates the subscriber" do
        described_class.unsubscribe!(subscriber, subscriptions, :unsubscribed)
        expect(subscriber.reload.deactivated?).to be_truthy
      end
    end
  end
end
