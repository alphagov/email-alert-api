RSpec.describe CreateSubscriptionService do
  let(:subscriber_list) { create :subscriber_list }
  let(:subscriber) { create :subscriber }
  let(:frequency) { "daily" }
  let(:user) { create :user }
  let(:args) { [subscriber_list, subscriber, frequency, user] }

  describe ".call" do
    it "creates a subscription if one does not exist" do
      new_subscription = described_class.call(*args)
      expect(new_subscription.subscriber_list).to eq subscriber_list
      expect(new_subscription.subscriber).to eq subscriber
      expect(new_subscription.frequency).to eq frequency
      expect(new_subscription.source).to eq "user_signed_up"
    end

    it "replaces a subscription if the frequencies differ" do
      subscription = create(
        :subscription,
        subscriber_list:,
        subscriber:,
        frequency: "weekly",
      )

      new_subscription = described_class.call(*args)

      expect(subscription.reload).to be_ended
      expect(subscription.ended_reason).to eq "frequency_changed"

      expect(new_subscription.subscriber_list).to eq subscriber_list
      expect(new_subscription.subscriber).to eq subscriber
      expect(new_subscription.frequency).to eq frequency
      expect(new_subscription.source).to eq "frequency_changed"
    end

    it "preserves a subscription if the frequency is unchanged" do
      subscription = create(
        :subscription,
        subscriber_list:,
        subscriber:,
        frequency:,
      )

      new_subscription = described_class.call(*args)
      expect(new_subscription).to eq subscription
    end

    it "ignores subscriptions that were previously ended" do
      create(
        :subscription,
        :ended,
        subscriber_list:,
        subscriber:,
        frequency:,
      )

      new_subscription = described_class.call(*args)
      expect(new_subscription).to_not be_ended
      expect(new_subscription.frequency).to eq frequency
      expect(new_subscription.source).to eq "user_signed_up"
    end

    it "raises a RecordInvalid error if the frequency is invalid" do
      expect { described_class.call(subscriber_list, subscriber, "foo", user) }
        .to raise_error ActiveRecord::RecordInvalid
    end
  end
end
