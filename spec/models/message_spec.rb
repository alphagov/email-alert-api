RSpec.describe Message do
  describe "url validation" do
    it "is valid when url is nil" do
      expect(build(:message, url: nil)).to be_valid
    end

    it "is invalid when url is incorrectly formatted" do
      expect(build(:message, url: "bad url")).to be_invalid
    end

    it "is valid when url is root-relative" do
      expect(build(:message, url: "/test?query=this#anchor")).to be_valid
    end

    it "is invalid when url is relative but not a root path" do
      expect(build(:message, url: "test")).to be_invalid
    end

    it "is valid when url is absolute and uses a https scheme" do
      expect(build(:message, url: "https://example.com/test")).to be_valid
    end

    it "is invalid when url lacks a scheme" do
      expect(build(:message, url: "//example.com/test")).to be_invalid
    end

    it "is invalid when url doesn't use https" do
      expect(build(:message, url: "http://example.com/test")).to be_invalid
    end
  end

  describe "criteria_rules validation" do
    it "is valid with criteria_rules are valid" do
      message = build(:message, criteria_rules: [
        { type: "tag", key: "topic", value: "a" },
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

  describe "sender_message_id validation" do
    it "is valid when nil" do
      message = build(:message, sender_message_id: nil)
      expect(message).to be_valid
    end

    it "is valid with a UUID" do
      message = build(:message, sender_message_id: SecureRandom.uuid)
      expect(message).to be_valid
    end

    it "is not valid without a UUID" do
      message = build(:message, sender_message_id: "12345")
      expect(message).not_to be_valid
    end

    it "disallows a non unique sender_message_id" do
      uuid = SecureRandom.uuid
      create(:message, sender_message_id: uuid)
      message = build(:message, sender_message_id: uuid)
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
          .to(Time.zone.now)
      end
    end
  end
end
