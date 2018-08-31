RSpec.describe ContentChangesForEmailQuery do
  describe ".call" do
    let!(:email) { create(:email) }
    let!(:content_change) { create(:content_change) }

    subject(:content_changes) { described_class.call(email) }

    before :each do
      create(:subscription_content, email: create(:email), content_change: create(:content_change))
      create(:subscription_content, email: create(:email), content_change: content_change)
    end

    context "when there are no subscription content associations" do
      it "returns an empty scope" do
        expect(subject.exists?).to be false
      end
    end

    context "when there are multiple subscription content associations" do
      before do
        create(:subscription_content, email: email, content_change: content_change)
        create(:subscription_content, email: email, content_change: content_change)
      end

      it "returns a scope of the unique content changes" do
        expect(subject).to match_array([content_change])
      end
      it "returns a scope with two content changes" do
        second_content_change = create(:content_change)
        create(:subscription_content, email: email, content_change: second_content_change)
        expect(subject).to match_array([content_change, second_content_change])
      end
    end
  end
end
