RSpec.describe ManageSubscriptionsLinkPresenter do
  describe ".call" do
    it "returns a manage subscriptions link" do
      subscriber = create(:subscriber, address: "test-email@test.com")
      expected = "[View, unsubscribe or change the frequency of your subscriptions](http://www.dev.gov.uk/email/manage/authenticate?address=test-email%40test.com)"
      expect(described_class.call(subscriber)).to eq(expected)
    end
  end
end
