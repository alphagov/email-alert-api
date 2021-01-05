RSpec.describe BulkEmailBodyPresenter do
  describe ".call" do
    it "substitutes the list URL in the body" do
      subscriber_list = build(:subscriber_list, url: "/url")
      body = "something [link](%LISTURL%)."

      allow(PublicUrls).to receive(:url_for)
        .with(base_path: "/url")
        .and_return("domain/url")

      result = described_class.call(body, subscriber_list)
      expect(result).to include("something [link](domain/url).")
    end

    it "copes when the subscriber list has no URL" do
      subscriber_list = build(:subscriber_list)

      expect { described_class.call("body", subscriber_list) }
        .to_not raise_error
    end
  end
end
