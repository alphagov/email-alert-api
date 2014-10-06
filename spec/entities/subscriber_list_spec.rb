require "spec_helper"

require "subscriber_list"
require "json"

RSpec.describe SubscriberList do
  subject(:subscriber_list) {
    SubscriberList.new(
      id,
      title,
      subscription_url,
      gov_delivery_id,
      created_at,
      tags,
    )
  }

  let(:id) { double(:id) }
  let(:title) { double(:title) }
  let(:subscription_url) { double(:subscription_url) }
  let(:gov_delivery_id) { double(:gov_delivery_id) }
  let(:tags) { double(:tags) }
  let(:created_at) { double(:created_at, iso8601: formatted_time) }
  let(:formatted_time) { "2014-10-06T14:00:00 UTC" }

  describe "#to_json" do
    it "formats the Time object to iso8601" do
      expect(subscriber_list.to_json).to include(
        %{"created_at":"#{formatted_time}"}
      )
    end
  end
end
