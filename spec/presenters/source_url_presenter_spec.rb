RSpec.describe SourceUrlPresenter do
  describe ".call" do
    let(:utm_params) { { utm_source: "source", utm_content: "content" } }

    it "returns nil if the list has no URL" do
      expect(described_class.call(nil, **utm_params)).to be_nil
    end

    it "returns nil if the URL is not for the Brexit Checker" do
      expect(described_class.call("/a-url", **utm_params)).to be_nil
    end

    context "for new-style Brexit Checker results" do
      it "returns a markdown URL to the results" do
        url = "/transition-check/results?foo=bar"

        allow(PublicUrls).to receive(:url_for)
          .with(utm_params.merge(base_path: url))
          .and_return("public_url")

        expect(described_class.call(url, **utm_params)).to eq(
          "[You can view a copy of your results on GOV.UK](public_url)",
        )
      end
    end

    context "for old-style Brexit Checker results" do
      it "returns a markdown URL to the results" do
        url = "/get-ready-brexit-check/results?foo=bar"

        allow(PublicUrls).to receive(:url_for)
          .with(utm_params.merge(base_path: url))
          .and_return("public_url")

        expect(described_class.call(url, **utm_params)).to eq(
          "[You can view a copy of your results on GOV.UK](public_url)",
        )
      end
    end
  end
end
