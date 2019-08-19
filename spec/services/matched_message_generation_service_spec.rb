RSpec.describe MatchedMessageGenerationService do
  let(:message) do
    create(:message, tags: { topics: ["oil-and-gas/licensing"] })
  end

  before do
    create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } })
  end

  describe ".call" do
    it "creates a MatchedMessage" do
      expect { described_class.call(message: message) }
        .to change { MatchedMessage.count }.by(1)
    end
  end
end
