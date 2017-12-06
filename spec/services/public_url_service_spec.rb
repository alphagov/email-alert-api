require "rails_helper"

RSpec.describe PublicUrlService do
  describe ".content_url" do
    it "returns the GOV.UK url for the content item" do
      result = subject.content_url(base_path: "/foo/bar")
      expect(result).to eq("http://www.dev.gov.uk/foo/bar")
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

  describe ".unsubscribe_url" do
    it "returns the GOV.UK url to unsubscribe for a subscription" do
      result = subject.unsubscribe_url(uuid: "foo-bar", title: "Foo & Bar")
      expect(result).to eq("http://www.dev.gov.uk/email/unsubscribe/foo-bar?title=Foo%20%26%20Bar")
    end
  end
end
