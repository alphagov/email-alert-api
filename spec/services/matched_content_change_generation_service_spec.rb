RSpec.describe MatchedContentChangeGenerationService do
  let(:content_change) do
    create(:content_change, tags: { topics: ["oil-and-gas/licensing"] })
  end

  let(:another_content_change) do
    create(:content_change, tags: { organisation: ["oil-and-gas/licensing"], format: %w[employment_tribunal_decision] })
  end

  before do
    create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } })
    create(:or_joined_facet_subscriber_list, tags: { organisation: { any: ["oil-and-gas/licensing"] } })
  end

  describe ".call" do
    it "creates a MatchedContentChange for an SubscriberList" do
      expect { described_class.call(content_change: content_change) }
        .to change { MatchedContentChange.count }.by(1)
    end

    it "creates a MatchedContentChange for an OrJoinedFacetSubscriberList" do
      expect { described_class.call(content_change: another_content_change) }
          .to change { MatchedContentChange.count }.by(1)
    end
  end
end
