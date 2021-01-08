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

    it "adds default UTM params if applicable" do
      result = subject.url_for(base_path: "/foo/bar?foo=bar", utm_source: "source")
      expect(result).to include("utm_source=source")
      expect(result).to include("utm_medium=email")
      expect(result).to include("utm_campaign=govuk-notifications")
    end

    it "allows default UTM params to be overridden" do
      result = subject.url_for(base_path: "/foo/bar?foo=bar", utm_source: "source", utm_campaign: "other")
      expect(result).to include("utm_campaign=other")
      expect(result).to_not include("utm_campaign=govuk-notifications")
    end
  end

  describe ".unsubscribe" do
    let(:subscription) { create :subscription }

    before do
      allow(AuthTokenGeneratorService)
        .to receive(:call)
        .with(subscriber_id: subscription.subscriber_id)
        .and_return("token")
    end

    it "returns the GOV.UK url for a one-click unsubscribe" do
      url = subject.unsubscribe(subscription)
      expect(url).to eq("http://www.dev.gov.uk/email/unsubscribe/#{subscription.id}?token=token")
    end

    it "accepts additional UTM params" do
      url = subject.unsubscribe(subscription, utm_source: "source")
      expect(url).to include("utm_source=source")
    end
  end

  describe ".manage_url" do
    let(:subscriber) { create(:subscriber, address: "foo@bar.com") }

    it "returns the GOV.UK url to manage subscriptions" do
      url = subject.manage_url(subscriber)
      expect(url).to eq("http://www.dev.gov.uk/email/manage/authenticate?address=foo%40bar.com")
    end

    it "accepts additional UTM params" do
      url = subject.manage_url(subscriber, utm_source: "source")
      expect(url).to include("utm_source=source")
    end
  end
end
