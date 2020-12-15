RSpec.describe SourceUrlPresenter do
  describe ".call" do
    it "returns nil if the list has no URL" do
      expect(described_class.call(nil)).to be_nil
    end

    it "returns nil if the URL is not for the Brexit Checker" do
      expect(described_class.call("/a-url")).to be_nil
    end

    it "returns a markdown URL to view Brexit Checker results" do
      url = "/transition-check/results?foo=bar"

      expect(described_class.call(url)).to eq(
        "[You can view a copy of your results on GOV.UK](http://www.dev.gov.uk#{url})",
      )
    end
  end
end
