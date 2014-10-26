require "rails_helper"

RSpec.describe "Getting a subscriber list", type: :request do
  include GovDeliveryHelpers

  context "when present" do
    before do
      FactoryGirl.create(:subscriber_list, tags: {topics: ["oil-and-gas/licensing"]})
    end

    it "returns a 200" do
      get_subscriber_list(topics: ["oil-and-gas/licensing"])

      expect(response.status).to eq(200)
    end

    it "returns the matching subscriber list" do
      get_subscriber_list(topics: ["oil-and-gas/licensing"])

      response_hash = JSON.parse(response.body)

      expect(response_hash.keys.to_set).to eq([
        "id",
        "title",
        "subscription_url",
        "gov_delivery_id",
        "created_at",
        "updated_at",
        "tags"
      ].to_set)

      expect(response_hash).to include(
        "tags" => {
          "topics" => ["oil-and-gas/licensing"]
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
    get "/subscriber-lists", tags: tags
  end
end
