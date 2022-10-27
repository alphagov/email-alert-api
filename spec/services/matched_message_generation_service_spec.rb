RSpec.describe MatchedMessageGenerationService do
  let(:message) do
    create(
      :message,
      criteria_rules: [
        { type: "tag", key: "topics", value: "oil-and-gas/licensing" },
      ],
    )
  end

  let!(:subscriber_list) do
    create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } })
  end

  describe ".call" do
    it "creates a MatchedMessage" do
      expect { described_class.call(message) }
        .to change { MatchedMessage.count }.by(1)
    end

    it "copes when there aren't any subscriber lists for the message" do
      no_match_message = create(:message)
      expect { described_class.call(no_match_message) }
        .to_not(change { MatchedMessage.count })
    end

    it "copes and does nothing when the MatchedMessage records already exists" do
      MatchedMessage.create!(message:, subscriber_list:)

      expect { described_class.call(message) }
        .to_not(change { MatchedMessage.count })
    end
  end
end
