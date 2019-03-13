RSpec.describe ContentChange do
  describe "#mark_processed!" do
    subject { create(:content_change) }

    it "sets processed_at" do
      Timecop.freeze do
        expect { subject.mark_processed! }
          .to change(subject, :processed_at)
          .from(nil)
          .to(Time.now)
      end
    end
  end

  describe "#content_purpose_supergroup" do
    let(:content_item) { create(:content_change, document_type: 'news_story') }
    let(:content_item_with_other_supergroup) { create(:content_change, document_type: 'edition') }

    it "is a supergroup type" do
      supertypes = GovukDocumentTypes.supertypes(document_type: 'news_story')
      expect(content_item.content_purpose_supergroup).to be(supertypes.fetch('content_purpose_supergroup'))
    end

    it "is nil when it is part of the 'other' supergroup" do
      expect(content_item_with_other_supergroup.content_purpose_supergroup).to be(nil)
    end
  end
end
