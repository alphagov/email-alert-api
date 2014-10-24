require "rails_helper"

RSpec.describe "Creating a subscriber list", type: :request do
  include GovDeliveryHelpers

  before do
    stub_gov_delivery_topic_creation
  end

  it "returns a 201" do
    create_subscriber_list(topics: ["oil-and-gas/licensing"])

    expect(response.status).to eq(201)
  end

  it "returns the created subscriber list" do
    create_subscriber_list(topics: ["oil-and-gas/licensing"])

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

  def create_subscriber_list(tags)
    post "/subscriber-lists", {
      title: "This is a sample title",
      gov_delivery_id: "UKGOVUK_1234",
      tags: tags
    }
  end
end
