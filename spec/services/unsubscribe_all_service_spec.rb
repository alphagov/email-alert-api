RSpec.describe UnsubscribeAllService do
  describe ".call" do
    let(:subscriber) { create(:subscriber) }

    before do
      create_list(:subscription, 2, subscriber:)
    end

    it "ends the active subscriptions" do
      described_class.call(subscriber, :unsubscribed)
      expect(subscriber.active_subscriptions.count).to eq 0
    end

    it "records how many subscriptions have been ended" do
      expect(Metrics).to receive(:unsubscribed).with(:unsubscribed, 2)
      described_class.call(subscriber, :unsubscribed)
    end
  end
end
