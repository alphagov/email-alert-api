RSpec.describe PublicUrls do
  describe ".url_for" do
    it "returns the GOV.UK url for the content item" do
      result = subject.url_for(base_path: "/foo/bar")
      expect(result).to eq("http://www.dev.gov.uk/foo/bar")
    end
  end

  describe ".subscription_url" do
    it "returns the GOV.UK url for the new subscription page" do
      result = subject.subscription_url(slug: "foo_bar")
      expect(result).to eq("http://www.dev.gov.uk/email/subscriptions/new?topic_id=foo_bar")
    end
  end

  describe ".absolute_url" do
    it "returns the absolute url given a base_path" do
      expect(subject.absolute_url(path: "redirect/to/path")).to eq("http://www.dev.gov.uk/redirect/to/path")
      expect(subject.absolute_url(path: "/redirect/to/path")).to eq("http://www.dev.gov.uk/redirect/to/path")
    end
  end

  describe ".unsubscribe" do
    it "returns the GOV.UK url for a one-click unsubscribe" do
      subscription = create :subscription

      allow(AuthTokenGeneratorService)
        .to receive(:call)
        .with(subscriber_id: subscription.subscriber_id)
        .and_return("token")

      expected = "http://www.dev.gov.uk/email/unsubscribe/#{subscription.id}?token=token"
      expect(subject.unsubscribe(subscription)).to eq(expected)
    end
  end
end
