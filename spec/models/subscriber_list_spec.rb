require "rails_helper"

RSpec.describe SubscriberList, type: :model do
  describe "#tags" do
    it "deserializes the tag arrays" do
      list = FactoryGirl.create(:subscriber_list, tags: {
        topics: ["environmental-management/boating"],
      })

      list.reload

      expect(list.tags).to eq(topics: ["environmental-management/boating"])
    end
  end

  describe "#subscription_url" do
    it "provides the subscription URL based on the gov_delivery_id" do
      list = SubscriberList.new(gov_delivery_id: "UKGOVUK_4567")

      expect(list.subscription_url).to eq(
        "http://govdelivery-public.example.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_4567"
      )
    end
  end
end
