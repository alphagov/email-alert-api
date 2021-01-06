RSpec.describe BulkEmailBodyPresenter do
  describe ".call" do
    it "substitutes the list URL in the body" do
      subscriber_list = build(:subscriber_list, url: "/url")
      body = "something [link](%LISTURL%)."

      allow(PublicUrls).to receive(:url_for)
        .with(
          base_path: "/url",
          utm_campaign: "govuk-notifications-bulk",
          utm_source: subscriber_list.slug,
          utm_medium: "email",
        )
        .and_return("domain/url")

      result = described_class.call(body, subscriber_list)
      expect(result).to include("something [link](domain/url).")
    end

    it "copes when the subscriber list has no URL" do
      subscriber_list = build(:subscriber_list)
      body = "something [link](%LISTURL%)."

      result = described_class.call(body, subscriber_list)
      expect(result).to include("something [link]().")
    end
  end
end
