RSpec.describe ContentChangesForEmailQuery do
  describe ".call" do
    let!(:email) { create(:email) }
    subject(:content_changes) { described_class.call(email) }

    context "when there are no subscription content associations" do
      it "returns an empty scope" do
        expect(content_changes.exists?).to be false
      end
    end

    context "when there are multiple subscription content associations" do
      let(:content_change) { create(:content_change) }
      before do
        create(:subscription_content, email: email, content_change: content_change)
        create(:subscription_content, email: email, content_change: content_change)
      end

      it "returns a scope of the unique content changes" do
        expect(content_changes.count).to eq 1
      end
    end
  end
end
