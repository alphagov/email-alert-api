RSpec.describe SubscriberList, type: :model do
  describe "validations" do
    subject { build(:subscriber_list) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "is valid when all values are blank - firehose" do
      subject.tags = {}
      subject.links = {}
      subject.document_type = ""
      subject.email_document_supertype = ""
      subject.government_document_supertype = ""

      expect(subject).to be_valid
    end

    it "is valid when tags 'hash' has 'any' values that are arrays" do
      subject.tags = { tribunal_decision_categories: { any: %w[pension] } }

      expect(subject).to be_valid
    end

    it "is valid when tags 'hash' has 'all' values that are arrays" do
      subject.tags = { tribunal_decision_categories: { all: %w[pension] } }

      expect(subject).to be_valid
    end

    it "is invalid when tags 'hash' has values that are not whitelisted" do
      subject.tags = {
        foo: { any: %w[pension] },
        dogs: { all: %w[bark] },
        organisations: { any: %w[pension] },
        people: { any: %w[pension] },
        world_locations: { all: %w[pension] },
      }

      expect(subject).to be_invalid
      expect(subject.errors[:tags]).to include("foo, dogs, organisations, people, and world_locations are not valid tags.")
    end

    it "is invalid when tags 'hash' has values that are not arrays" do
      subject.tags = { tribunal_decision_categories: { any: "pension" } }

      expect(subject).to be_invalid
      expect(subject.errors[:tags]).to include("All tag values must be sent as Arrays")
    end

    it "is valid when links 'hash' has 'any' values that are arrays" do
      subject.links = { foo: { any: %w[pension] } }

      expect(subject).to be_valid
    end

    it "is valid when links 'hash' has 'all' values that are arrays" do
      subject.links = { foo: { all: %w[pension] } }

      expect(subject).to be_valid
    end

    it "is invalid when links 'hash' has 'any' values that are not arrays" do
      subject.links = { foo: { any: "pension" } }

      expect(subject).to be_invalid
      expect(subject.errors[:links]).to include("All link values must be sent as Arrays")
    end

    it "is invalid when links 'hash' has 'all' values that are not arrays" do
      subject.links = { foo: { all: "pension" } }

      expect(subject).to be_invalid
      expect(subject.errors[:links]).to include("All link values must be sent as Arrays")
    end

    describe "url" do
      it "is valid when url is nil" do
        expect(build(:subscriber_list, url: nil)).to be_valid
      end

      it "is valid when url is an absolute path" do
        expect(build(:subscriber_list, url: "/test")).to be_valid
      end

      it "is invalid when url is an absolute URI" do
        expect(build(:subscriber_list, url: "https://example.com/test")).to be_invalid
      end
    end
  end

  context "when a subscriber_list is deleted" do
    subject { create(:subscriber_list) }
    let!(:a_sanity_check_list) { build(:subscriber_list) }
    let!(:subscriber) { create(:subscriber) }
    let!(:subscriber2) { create(:subscriber) }
    let!(:subscription1) { create(:subscription, subscriber:, subscriber_list: subject) }
    let!(:subscription2) { create(:subscription, subscriber: subscriber2, subscriber_list: subject) }
    let!(:subscription3) { create(:subscription, subscriber:, subscriber_list: a_sanity_check_list) }

    it "will delete all dependent subscriptions" do
      expect { subject.destroy! }.to(change { subscriber.subscriptions.count }.by(-1))
    end

    it "will not delete subscribers" do
      expect { subject.destroy! }.not_to(change { Subscriber.count })
    end

    it "will not delete non-dependent subscriptions" do
      expect { subject.destroy! }.to(change { SubscriberList.count }.by(-1))
    end

    it "will not delete other subscriptions" do
      subject.destroy!
      expect(subscription3.reload.active?).to be true
    end
  end

  context "with a subscription" do
    subject { create(:subscriber_list) }

    before { create(:subscription, subscriber_list: subject) }

    it "can access the subscribers" do
      expect(subject.subscribers.size).to eq(1)
    end
  end

  describe "#tags" do
    it "deserializes the tag arrays" do
      list = create(:subscriber_list, tags: { tribunal_decision_categories: { any: %w[pension], all: %w[transfer-of-undertakings] } })
      list.reload

      expect(list.tags).to eq(tribunal_decision_categories: { any: %w[pension], all: %w[transfer-of-undertakings] })
    end
  end

  describe "matching_criteria_rules scope" do
    it "can look up subscriber lists that match criteria rules" do
      list = create(:subscriber_list, tags: { format: { any: %w[match] } })
      create(:subscriber_list)

      result = described_class.matching_criteria_rules(
        [
          { type: "tag", key: "format", value: "match" },
        ],
      )

      expect(result).to match([list])
    end
  end
end
