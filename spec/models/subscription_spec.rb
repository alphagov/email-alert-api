RSpec.describe Subscription, type: :model do
  describe "validations" do
    subject { build(:subscription) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "must be unique between subscriber and subscriber lists" do
      create(
        :subscription,
        subscriber: subject.subscriber,
        subscriber_list: subject.subscriber_list
      )

      expect(subject).to be_invalid
    end

    it "is an immediate email" do
      expect(subject.immediately?).to be_truthy
    end
  end

  describe "destroy" do
    subject { create(:subscription) }

    it "doesn't delete the record" do
      subject.destroy
      expect(described_class.find(subject.id)).to eq(subject)
    end

    it "sets ended_at to Time.now" do
      Timecop.freeze do
        subject.destroy
        expect(subject.ended_at).to eq(Time.now)
      end
    end
  end

  describe ".not_deleted" do
    it "returns subscriptions with ended_at nil" do
      create(:subscription)
      expect(Subscription.not_deleted.count).to eq(1)
    end

    it "doesn't return subscriptions with ended_at" do
      create(:subscription, ended_at: Time.now)
      expect(Subscription.not_deleted.count).to eq(0)
    end
  end
end
