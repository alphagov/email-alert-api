RSpec.describe PublicUrls do
  describe ".url_for" do
    it "returns the GOV.UK url for the content item" do
      result = subject.url_for(base_path: "/foo/bar")
      expect(result).to eq("http://www.dev.gov.uk/foo/bar")
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
