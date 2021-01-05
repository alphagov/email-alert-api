RSpec.describe BulkEmailBodyPresenter do
  describe ".call" do
    it "substitutes the list URL in the body" do
      subscriber_list = build(:subscriber_list, url: "/url")
      body = "something [link](%LISTURL%)."

      allow(PublicUrls).to receive(:url_for)
        .with(base_path: %r{^/url\?utm_source=})
        .and_return("domain/url")

      result = described_class.call(body, subscriber_list)
      expect(result).to include("something [link](domain/url).")
    end

    it "copes if the URL already has query params" do
      subscriber_list = build(:subscriber_list, url: "/url?foo=bar")

      expect(PublicUrls).to receive(:url_for)
        .with(base_path: %r{^/url\?foo=bar&utm_source})
        .and_call_original

      described_class.call("body", subscriber_list)
    end

    it "copes when the subscriber list has no URL" do
      subscriber_list = build(:subscriber_list)
      body = "something [link](%LISTURL%)."

      result = described_class.call(body, subscriber_list)
      expect(result).to include("something [link]().")
    end
  end
end
