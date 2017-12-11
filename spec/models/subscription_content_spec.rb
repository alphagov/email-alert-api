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
end
