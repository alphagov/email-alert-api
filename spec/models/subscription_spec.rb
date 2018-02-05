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

  describe "callbacks" do
    subject { build(:subscription) }

    it "sets a uuid before validation" do
      expect(subject.uuid).to be_nil

      expect(subject).to be_valid
      expect(subject.uuid).not_to be_nil
    end

    it "preserves the same uuid" do
      subject.valid?
      uuid = subject.uuid

      subject.valid?
      expect(subject.uuid).to eq(uuid)
    end
  end

  describe "destroy" do
    subject { create(:subscription) }

    it "doesn't delete the record" do
      subject.destroy
      expect(described_class.find(subject.id)).to eq(subject)
    end

    it "sets deleted_at to Time.now" do
      Timecop.freeze do
        subject.destroy
        expect(subject.deleted_at).to eq(Time.now)
      end
    end
  end

  describe ".not_deleted" do
    it "returns subscriptions with deleted_at nil" do
      create(:subscription)
      expect(Subscription.not_deleted.count).to eq(1)
    end

    it "doesn't return subscriptions with deleted_at" do
      create(:subscription, deleted_at: Time.now)
      expect(Subscription.not_deleted.count).to eq(0)
    end
  end
end
