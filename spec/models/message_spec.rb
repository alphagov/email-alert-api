RSpec.describe Message do
  describe "criteria_rules validation" do
    it "is valid with criteria_rules are valid" do
      message = build(
        :message,
        criteria_rules: [
          { type: "tag", key: "topic", value: "a" },
        ],
      )
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
end
