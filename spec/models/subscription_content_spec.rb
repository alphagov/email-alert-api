RSpec.describe SubscriptionContent do
  describe "validations" do
    subject { build(:subscription_content) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a subscription" do
      subject.subscription = nil
      expect(subject).to be_invalid
    end

    it "requires a content change" do
      subject.content_change = nil
      expect(subject).to be_invalid
    end
  end

  describe ".import_ignoring_duplicates" do
    let(:content_changes) { create_list(:content_change, 15) }
    let(:subscription) { create(:subscription) }
    let(:columns) { %i[content_change_id subscription_id] }
    let(:rows) { content_changes.map { |c| [c.id, subscription.id] } }

    it "can import a lot of items" do
      expect { described_class.import_ignoring_duplicates(columns, rows, batch_size: 5) }
        .to change { SubscriptionContent.count }
        .by(15)
    end

    it "can recover when there are duplicates" do
      rows.shuffle.take(5).each do |(content_change_id, subscription_id)|
        create(:subscription_content,
               content_change_id: content_change_id,
               subscription_id: subscription_id)
      end

      expect { described_class.import_ignoring_duplicates(columns, rows) }
        .to change { SubscriptionContent.count }
        .by(10)
    end
  end
end
