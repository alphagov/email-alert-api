RSpec.describe Email do
  describe "validations" do
    it "requires subject" do
      subject.valid?
      expect(subject.errors[:subject]).not_to be_empty
    end

    it "requires body" do
      subject.valid?
      expect(subject.errors[:body]).not_to be_empty
    end
  end
end
