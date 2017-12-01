require 'rails_helper'

RSpec.describe UnsubscribeLink do
  let(:subscription) { double(uuid: "1234", subscriber_list: double(title: title)) }
  let(:title) { "dave crocker & friends" }

  let(:unsubscribe_link) {
    UnsubscribeLink.new(subscription)
  }

  describe "#url" do
    it "returns an unsubscribe url for the subscription" do
      expect(unsubscribe_link.url).to eq(
        "http://www.dev.gov.uk/email/unsubscribe/1234?title=dave%20crocker%20%26%20friends"
      )
    end
  end

  describe "#title" do
    it "returns the name of the subscriber_list" do
      expect(unsubscribe_link.title).to eq("dave crocker & friends")
    end
  end

  describe ".for" do
    let(:other_subscription) do
      double(uuid: "5678", subscriber_list: double(title: "jarvis cocker & friends"))
    end

    let(:subscriptions) { [subscription, other_subscription] }

    it "builds an unsubscribe link for each subscription" do
      first, second = UnsubscribeLink.for(subscriptions)

      expect(first.title).to eq("dave crocker & friends")
      expect(second.title).to eq("jarvis cocker & friends")
    end
  end
end
