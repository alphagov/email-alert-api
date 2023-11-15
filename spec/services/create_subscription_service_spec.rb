RSpec.describe CreateSubscriptionService do
  let(:subscriber_list) { create :subscriber_list }
  let(:subscriber) { create :subscriber }
  let(:frequency) { "daily" }
  let(:user) { create :user }
  let(:args) { [subscriber_list, subscriber, frequency, user] }
  let(:new_subscription) { described_class.call(*args) }
  let(:subscription_record) { new_subscription[:record] }

  describe ".call" do
    it "creates a subscription if one does not exist" do
      expect(subscription_record.subscriber_list).to eq subscriber_list
      expect(subscription_record.subscriber).to eq subscriber
      expect(subscription_record.frequency).to eq frequency
      expect(subscription_record.source).to eq "user_signed_up"
      expect(new_subscription[:new_record]).to eq true
    end

    it "replaces a subscription if the frequencies differ" do
      subscription = create(
        :subscription,
        subscriber_list:,
        subscriber:,
        frequency: "weekly",
      )

      expect(subscription_record.subscriber_list).to eq subscriber_list
      expect(subscription_record.subscriber).to eq subscriber
      expect(subscription_record.frequency).to eq frequency
      expect(subscription_record.source).to eq "frequency_changed"
      expect(new_subscription[:new_record]).to eq true

      expect(subscription.reload).to be_ended
      expect(subscription.ended_reason).to eq "frequency_changed"
    end

    it "preserves a subscription if the frequency is unchanged" do
      subscription = create(
        :subscription,
        subscriber_list:,
        subscriber:,
        frequency:,
      )

      expect(subscription_record).to eq subscription
      expect(new_subscription[:new_record]).to eq false
    end

    it "ignores subscriptions that were previously ended" do
      create(
        :subscription,
        :ended,
        subscriber_list:,
        subscriber:,
        frequency:,
      )

      expect(subscription_record).to_not be_ended
      expect(subscription_record.frequency).to eq frequency
      expect(subscription_record.source).to eq "user_signed_up"
      expect(new_subscription[:new_record]).to eq true
    end

    it "raises a RecordInvalid error if the frequency is invalid" do
      expect { described_class.call(subscriber_list, subscriber, "foo", user) }
        .to raise_error ActiveRecord::RecordInvalid
    end
  end
end
