RSpec.describe ContentChange, type: :model do
  describe "validations" do
    subject { create(:content_change) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end
end
