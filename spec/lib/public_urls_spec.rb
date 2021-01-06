RSpec.describe PublicUrls do
  describe ".url_for" do
    it "returns a GOV.UK URL for a base path" do
      result = subject.url_for(base_path: "/foo/bar")
      expect(result).to eq("http://www.dev.gov.uk/foo/bar")
    end

    it "extends any query params in the URL" do
      result = subject.url_for(base_path: "/foo/bar?foo=bar", other: "param")
      expect(result).to eq("http://www.dev.gov.uk/foo/bar?foo=bar&other=param")
    end
  end

  describe ".unsubscribe" do
    it "returns the GOV.UK url for a one-click unsubscribe" do
      subscription = create :subscription

      allow(AuthTokenGeneratorService)
        .to receive(:call)
        .with(subscriber_id: subscription.subscriber_id)
        .and_return("token")

      url = subject.unsubscribe(subscription_id: subscription.id, subscriber_id: subscription.subscriber_id)
      expect(url).to eq("http://www.dev.gov.uk/email/unsubscribe/#{subscription.id}?token=token")
    end
  end
end
