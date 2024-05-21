RSpec.describe FindLatestMatchingSubscription do
  let!(:subscriber) { create(:subscriber) }
  let!(:subscriber_list) { create(:subscriber_list, tags: { tribunal_decision_categories: { any: %w[transfer-of-undertakings] } }) }
  let!(:original_subscription) { create_subscription(:ended, :daily, created_at: 5.days.ago) }
  # `let` (as opposed to `let!`) is lazy, so value will vary according to other subscriptions
  # that have been created, therefore we can safely assert against it
  let(:subject) { described_class.call(original_subscription) }

  context "when only one subscription exists" do
    it "should return the original subscription" do
      expect(subject).to eq(original_subscription)
    end
  end

  context "when an older subscription exists" do
    it "should return the original subscription" do
      create_subscription(:ended, :daily, created_at: 100.days.ago)
      expect(subject).to eq(original_subscription)
    end
  end

  context "when a newer subscription exists" do
    it "should return the newer subscription" do
      newer_subscription = create_subscription(:daily, created_at: Time.zone.now)
      expect(subject).to eq(newer_subscription)
    end

    it "should return the newer subscription, even if the frequency is different" do
      newer_subscription = create_subscription(:weekly, created_at: Time.zone.now)
      expect(subject).to eq(newer_subscription)
    end

    it "should return the newer subscription, even if that one has also ended" do
      newer_subscription = create_subscription(:daily, :ended, created_at: Time.zone.now)
      expect(subject).to eq(newer_subscription)
    end
  end

  def create_subscription(*traits, options)
    subscription_args = { subscriber_list:, subscriber: }.merge(options)
    create(:subscription, *traits, subscription_args)
  end
end
