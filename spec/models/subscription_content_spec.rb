RSpec.describe SubscriptionContent do
  describe "validations" do
    it "is valid for the default factory" do
      expect(build(:subscription_content)).to be_valid
    end

    it "is valid with a message" do
      expect(build(:subscription_content, :with_message)).to be_valid
    end

    it "is invalid with a message and a content_change" do
      subscription_content = build(
        :subscription_content,
        message: build(:message),
        content_change: build(:content_change),
      )
      expect(subscription_content).to be_invalid
    end

    it "is invalid without a message or a content_change" do
      subscription_content = build(
        :subscription_content,
        message: nil,
        content_change: nil,
      )
      expect(subscription_content).to be_invalid
    end
  end
end
