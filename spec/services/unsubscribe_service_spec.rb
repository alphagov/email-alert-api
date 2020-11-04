RSpec.describe UnsubscribeService do
  describe ".call" do
    let(:subscriber) { create(:subscriber, address: "foo@bar.com") }
    let(:subscriptions) { create_list(:subscription, 2, subscriber: subscriber) }

    it "ends the specified subscriptions" do
      described_class.call(subscriber, [subscriptions.first], :unsubscribed)
      expect(subscriber.active_subscriptions.count).to eq 1
    end
  end
end
