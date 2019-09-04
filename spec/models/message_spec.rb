RSpec.describe Message do
  describe "url validation" do
    it "is valid when url is nil" do
      expect(build(:message, url: nil)).to be_valid
    end

    it "is valid when url is an absolute path" do
      expect(build(:message, url: "/test")).to be_valid
    end

    it "is invalid when url is an absolute URI" do
      expect(build(:message, url: "https://example.com/test")).to be_invalid
    end
  end

  describe "criteria_rules validation" do
    it "is valid with criteria_rules are valid" do
      message = build(:message, criteria_rules: [
        { type: "tag", key: "topic", value: "a" }
      ])
      expect(message).to be_valid
    end

    it "is not valid with invalid criteria_rules" do
      message = build(:message, criteria_rules: [])
      expect(message).not_to be_valid
    end

    it "is not valid without criteria rules" do
      message = build(:message, criteria_rules: nil)
      expect(message).not_to be_valid
    end
  end

  describe "#mark_processed!" do
    it "sets processed_at" do
      Timecop.freeze do
        message = create(:message)
        expect { message.mark_processed! }
          .to change(message, :processed_at)
          .from(nil)
          .to(Time.now)
      end
    end
  end
end
