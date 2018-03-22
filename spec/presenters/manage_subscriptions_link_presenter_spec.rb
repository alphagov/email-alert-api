require "rails_helper"

RSpec.describe ManageSubscriptionsLinkPresenter do
  describe ".call" do
    it "returns a manage subscriptions link" do
      expected = "[Manage your subscriptions](http://www.dev.gov.uk/email/authentication?id=1)"
      expect(described_class.call(subscriber_id: 1)).to eq(expected)
    end
  end
end
