RSpec.describe PublicUrlService do
  describe ".url_for" do
    it "returns the GOV.UK url for the content item" do
      result = subject.url_for(base_path: "/foo/bar")
      expect(result).to eq("http://www.dev.gov.uk/foo/bar")
    end
  end

  describe ".subscription_url" do
    it "returns the GOV.UK for the new subscription page" do
      result = subject.subscription_url(gov_delivery_id: "foo_bar")
      expect(result).to eq("http://www.dev.gov.uk/email/subscriptions/new?topic_id=foo_bar")
    end
  end

  describe ".deprecated_subscription_url" do
    it "returns the govdelivery URL for creating a new subscription" do
      result = subject.deprecated_subscription_url(gov_delivery_id: "foo_bar")

      expect(result).to eq(
        "http://govdelivery-public.example.com/accounts/UKGOVUK/subscriber/new?topic_id=foo_bar"
      )
    end
  end
end
