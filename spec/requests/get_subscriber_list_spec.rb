require "rails_helper"

RSpec.describe "Getting a subscriber list", type: :request do
  include GovDeliveryHelpers

  context "when present" do
    before do
      create(:subscriber_list, tags: {topics: ["oil-and-gas/licensing", "drug-device-alert"]})
    end

    it "returns a 200" do
      get_subscriber_list(topics: ["drug-device-alert", "oil-and-gas/licensing"])

      expect(response.status).to eq(200)
    end

    it "returns the matching subscriber list" do
      get_subscriber_list(topics: ["drug-device-alert", "oil-and-gas/licensing"])

      response_hash = JSON.parse(response.body)

      subscriber_list = response_hash["subscriber_list"]

      expect(subscriber_list.keys.to_set).to eq([
        "id",
        "title",
        "subscription_url",
        "gov_delivery_id",
        "created_at",
        "updated_at",
        "tags"
      ].to_set)

      expect(subscriber_list).to include(
        "tags" => {
          "topics" => ["oil-and-gas/licensing", "drug-device-alert"]
        }
      )
    end
  end

  context "when not present" do
    it "404s" do
      get_subscriber_list(topics: ["oil-and-gas/licensing"])

      expect(response.status).to eq(404)
    end
  end

  def get_subscriber_list(tags)
    get "/subscriber-lists", { tags: tags }, json_headers
  end
end
