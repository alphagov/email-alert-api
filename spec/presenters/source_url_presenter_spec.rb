RSpec.describe SourceUrlPresenter do
  describe ".call" do
    it "returns nil if the list has no URL" do
      expect(described_class.call(nil)).to be_nil
    end

    it "returns nil if the URL is not for the Brexit Checker" do
      expect(described_class.call("/a-url")).to be_nil
    end

    context "for new-style Brexit Checker results" do
      it "returns a markdown URL to the results" do
        url = "/transition-check/results?foo=bar"

        allow(PublicUrls).to receive(:url_for)
          .with(base_path: url).and_return("public_url")

        expect(described_class.call(url)).to eq(
          "[You can view a copy of your results on GOV.UK](public_url)",
        )
      end
    end

    context "for old-style Brexit Checker results" do
      it "returns a markdown URL to the results" do
        url = "/get-ready-brexit-check/results?foo=bar"

        allow(PublicUrls).to receive(:url_for)
          .with(base_path: url).and_return("public_url")

        expect(described_class.call(url)).to eq(
          "[You can view a copy of your results on GOV.UK](public_url)",
        )
      end
    end
  end
end
