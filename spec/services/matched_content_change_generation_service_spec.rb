RSpec.describe MatchedContentChangeGenerationService do
  let(:content_change) do
    create(:content_change, tags: { topics: ["oil-and-gas/licensing"] })
  end

  before do
    create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } })
  end

  describe ".call" do
    it "creates a MatchedContentChange" do
      expect { described_class.call(content_change) }
        .to change { MatchedContentChange.count }.by(1)
    end
  end
end
