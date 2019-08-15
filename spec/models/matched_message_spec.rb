RSpec.describe MatchedMessage do
  it "is valid for the default factory" do
    expect(build(:matched_message)).to be_valid
  end
end
