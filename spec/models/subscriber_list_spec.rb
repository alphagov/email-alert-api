RSpec.describe SubscriberList, type: :model do
  describe "validations" do
    subject { build(:subscriber_list) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "is valid when all values are blank - firehose" do
      subject.tags = {}
      subject.links = {}
      subject.document_type = ''
      subject.email_document_supertype = ''
      subject.government_document_supertype = ''

      expect(subject).to be_valid
    end

    it "is valid when tags 'hash' has 'any' values that are arrays" do
      subject.tags = { foo: { any: %w[bar] } }

      expect(subject).to be_valid
    end

    it "is valid when tags 'hash' has 'all' values that are arrays" do
      subject.tags = { foo: { all: %w[bar] } }

      expect(subject).to be_valid
    end

    it "is invalid when tags 'hash' has values that are not arrays" do
      subject.tags = { foo: { any: "bar" } }

      expect(subject).to be_invalid
      expect(subject.errors[:tags]).to include("All tag values must be sent as Arrays")
    end

    it "is valid when links 'hash' has 'any' values that are arrays" do
      subject.links = { foo: { any: %w[bar] } }

      expect(subject).to be_valid
    end

    it "is valid when links 'hash' has 'all' values that are arrays" do
      subject.links = { foo: { all: %w[bar] } }

      expect(subject).to be_valid
    end

    it "is invalid when links 'hash' has 'any' values that are not arrays" do
      subject.links = { foo: { any: "bar" } }

      expect(subject).to be_invalid
      expect(subject.errors[:links]).to include("All link values must be sent as Arrays")
    end

    it "is invalid when links 'hash' has 'all' values that are not arrays" do
      subject.links = { foo: { all: "bar" } }

      expect(subject).to be_invalid
      expect(subject.errors[:links]).to include("All link values must be sent as Arrays")
    end

    it "is not recognised as travel advice" do
      expect(subject.is_travel_advice?).to be false
    end

    it "is not recognised as medical safety alert" do
      expect(subject.is_medical_safety_alert?).to be false
    end
  end

  context "with a subscription" do
    subject { create(:subscriber_list) }

    before { create(:subscription, subscriber_list: subject) }

    it "can access the subscribers" do
      expect(subject.subscribers.size).to eq(1)
    end

    it "cannot be deleted" do
      expect {
        subject.destroy
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  context "with a travel advice subscriber list" do
    subject { build(:subscriber_list, :travel_advice) }

    it "is recognised as travel advice" do
      expect(subject.is_travel_advice?).to be true
    end
  end

  context "with a medical safety alert subscriber list" do
    subject { build(:subscriber_list, :medical_safety_alert) }

    it "is recognised as a medical safety alert" do
      expect(subject.is_medical_safety_alert?).to be true
    end
  end

  describe "#tags" do
    it "deserializes the tag arrays" do
      list = create(:subscriber_list, tags: { topics: { any: ["environmental-management/boating"], all: ["oil-and-gas/licensing"] } })
      list.reload

      expect(list.tags).to eq(topics: { any: ["environmental-management/boating"], all: ["oil-and-gas/licensing"] })
    end
  end

  describe "#subscription_url" do
    subject { SubscriberList.new(slug: "UKGOVUK_4567") }

    it "returns the correct subscription URL" do
      expect(subject.subscription_url).to eq(
        "http://www.dev.gov.uk/email/subscriptions/new?topic_id=UKGOVUK_4567"
      )
    end
  end
end
