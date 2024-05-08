RSpec.describe MatchedContentChangeGenerationService do
  let(:content_change) do
    create(:content_change, tags: { tribunal_decision_categories: %w[transfer-of-undertakings] })
  end

  let!(:subscriber_list) do
    create(:subscriber_list, tags: { tribunal_decision_categories: { any: %w[transfer-of-undertakings] } })
  end

  describe ".call" do
    it "creates a MatchedContentChange" do
      expect { described_class.call(content_change) }
        .to change { MatchedContentChange.count }.by(1)
    end

    it "copes when there aren't any subscriber lists for the content change" do
      no_match_content_change = create(:content_change)
      expect { described_class.call(no_match_content_change) }
        .to_not(change { MatchedContentChange.count })
    end

    it "copes and does nothing when the MatchedContentChange records already exists" do
      MatchedContentChange.create!(content_change:,
                                   subscriber_list:)

      expect { described_class.call(content_change) }
        .to_not(change { MatchedContentChange.count })
    end
  end
end
