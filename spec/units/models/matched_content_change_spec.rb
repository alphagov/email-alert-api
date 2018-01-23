RSpec.describe MatchedContentChange, type: :model do
  context "validations" do
    subject { build(:matched_content_change) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end
end
