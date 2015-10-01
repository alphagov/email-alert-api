require "rails_helper"

RSpec.describe "Creating a subscriber list", type: :request do
  include GovDeliveryHelpers

  before do
    stub_gov_delivery_topic_creation
  end

  it "returns a 201" do
    create_subscriber_list(tags: {topics: ["oil-and-gas/licensing"]})

    expect(response.status).to eq(201)
  end

  it "returns the created subscriber list" do
    create_subscriber_list(
      tags: {topics: ["oil-and-gas/licensing"]},
      links: {topics: ["uuid-888"]}
    )
    response_hash = JSON.parse(response.body)
    subscriber_list = response_hash["subscriber_list"]

    expect(subscriber_list.keys.to_set).to eq(
      %w{
        id
        title
        subscription_url
        gov_delivery_id
        created_at
        updated_at
        tags
        links
      }.to_set
    )
    expect(subscriber_list).to include(
      "tags" => {
        "topics" => ["oil-and-gas/licensing"]
      },
      "links" => {
        "topics" => ["uuid-888"]
      }
    )
  end

  it "returns an error if tag isn't an array" do
    create_subscriber_list(
      tags: {topics: "oil-and-gas/licensing"},
    )

    expect(response.status).to eq(422)
  end

  it "returns an error if link isn't an array" do
    create_subscriber_list(
      links: {topics: "uuid-888"},
    )

    expect(response.status).to eq(422)
  end

  def create_subscriber_list(tags: {}, links: {})
    request_body = JSON.dump({
      title: "This is a sample title",
      gov_delivery_id: "UKGOVUK_1234",
      tags: tags,
      links: links
    })

    post "/subscriber-lists", request_body, json_headers
  end
end
