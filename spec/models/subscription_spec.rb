RSpec.describe Subscription, type: :model do
  describe "validations" do
    subject { create(:subscription) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "has no ended reason" do
      expect(subject.ended_reason).to be_nil
    end

    it "is an immediate email" do
      expect(subject.immediately?).to be_truthy
    end
  end

  describe "deletion behaviour" do
    subject { create(:subscription) }
    let!(:subscription_content) { create(:subscription_content, subscription: subject) }

    it "deletes associated subscription_contents" do
      expect { subject.destroy }.to(change {
        SubscriptionContent.count
      }.by(-1))
    end
  end

  describe ".active" do
    it "returns subscriptions with ended_at nil" do
      create(:subscription)
      expect(Subscription.active.count).to eq(1)
    end

    it "doesn't return subscriptions with ended_at" do
      create(:subscription, :ended)
      expect(Subscription.active.count).to eq(0)
    end
  end

  describe ".ended" do
    it "returns subscriptions with ended_at nil" do
      create(:subscription, :ended)
      expect(Subscription.ended.count).to eq(1)
    end

    it "doesn't return subscriptions with ended_at" do
      create(:subscription)
      expect(Subscription.ended.count).to eq(0)
    end
  end

  describe ".active_on" do
    before do
      create(:subscription, created_at: "2018-01-01", ended_at: "2019-01-01")
    end

    it "returns subscriptions active on a valid date" do
      expect(Subscription.active_on("2018-06-01").count).to eq(1)
    end

    it "returns no subscriptions active on an invalid date" do
      expect(Subscription.active_on("2019-02-01").count).to eq(0)
    end
  end

  describe ".for_content_change" do
    it "returns subscriptions associated with a content change" do
      associated_subscription = create(:subscription)
      associated_content_change = create(:content_change)
      create(
        :matched_content_change,
        subscriber_list: associated_subscription.subscriber_list,
        content_change: associated_content_change,
      )
      unassociated_subscription = create(:subscription)
      unassociated_content_change = create(:content_change)
      create(
        :matched_content_change,
        subscriber_list: unassociated_subscription.subscriber_list,
        content_change: unassociated_content_change,
      )

      expect(Subscription.for_content_change(associated_content_change))
        .to include(associated_subscription)
      expect(Subscription.for_content_change(associated_content_change))
        .not_to include(unassociated_subscription)
    end
  end

  describe ".for_message" do
    it "returns subscriptions associated with a message" do
      associated_subscription = create(:subscription)
      associated_message = create(:message)
      create(
        :matched_message,
        subscriber_list: associated_subscription.subscriber_list,
        message: associated_message,
      )
      unassociated_subscription = create(:subscription)
      unassociated_message = create(:message)
      create(
        :matched_message,
        subscriber_list: unassociated_subscription.subscriber_list,
        message: unassociated_message,
      )

      expect(Subscription.for_message(associated_message))
        .to include(associated_subscription)
      expect(Subscription.for_message(associated_message))
        .not_to include(unassociated_subscription)
    end
  end

  describe ".dedup_by_subscriber" do
    it "returns the latest subscription for a subscriber" do
      subscriber = create(:subscriber)
      create(:subscription, subscriber:, created_at: 2.days.ago)

      expected = [
        create(:subscription, subscriber:).id,
        create(:subscription, subscriber: create(:subscriber)).id,
      ]

      expect(Subscription.dedup_by_subscriber).to match_array(expected)
    end

    it "respects any previous scopes applied to the model" do
      create(:subscription, :ended)
      create(:subscription, frequency: "daily")

      create(:subscription)
      expect(Subscription.active.immediately.dedup_by_subscriber.count).to eq(1)
    end
  end

  describe "#end" do
    subject { create(:subscription) }

    it "doesn't delete the record" do
      subject.end(reason: :unsubscribed)
      expect(described_class.find(subject.id)).to eq(subject)
    end

    it "sets ended_at to Time.now" do
      freeze_time do
        subject.end(reason: :unsubscribed)
        expect(subject.ended_at).to eq(Time.zone.now)
      end
    end

    it "reports unsubscribe metrics" do
      expect(Metrics).to receive(:unsubscribed).with(:unsubscribed)
      subject.end(reason: :unsubscribed)
    end
  end
end
