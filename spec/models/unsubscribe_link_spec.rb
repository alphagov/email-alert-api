RSpec.describe UnsubscribeLink do
  let!(:subscription) { create(:subscription, uuid: "e7883dd9-b690-41c9-8fa6-2857c3fff3bd", subscriber_list: create(:subscriber_list, title: title)) }

  let(:title) { "dave crocker & friends" }

  let(:unsubscribe_link) {
    UnsubscribeLink.new(title: subscription.subscriber_list.title, uuid: subscription.uuid)
  }

  describe "#url" do
    it "returns an unsubscribe url for the subscription" do
      expect(unsubscribe_link.url).to eq(
        "http://www.dev.gov.uk/email/unsubscribe/e7883dd9-b690-41c9-8fa6-2857c3fff3bd?title=dave%20crocker%20%26%20friends"
      )
    end
  end

  describe "#title" do
    it "returns the name of the subscriber_list" do
      expect(unsubscribe_link.title).to eq("dave crocker & friends")
    end
  end

  describe ".for" do
    before do
      create(:subscription, subscriber_list: create(:subscriber_list, title: "jarvis cocker & friends"))
    end

    let(:subscriptions) { Subscription.all }

    it "builds an unsubscribe link for each subscription" do
      first, second = UnsubscribeLink.for(subscriptions)

      expect(first.title).to eq("dave crocker & friends")
      expect(second.title).to eq("jarvis cocker & friends")
    end
  end
end
