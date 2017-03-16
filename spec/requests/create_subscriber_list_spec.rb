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
        document_type
        subscription_url
        gov_delivery_id
        created_at
        updated_at
        tags
        links
        enabled
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

  describe "creating a subscriber list with a document_type" do
    it "returns a 201" do
      create_subscriber_list(document_type: "travel_advice")

      expect(response.status).to eq(201)
    end

    it "sets the document_type on the subscriber list" do
      create_subscriber_list(
        tags: { countries: ["andorra"] },
        document_type: "travel_advice"
      )

      subscriber_list = SubscriberList.last
      expect(subscriber_list.document_type).to eq("travel_advice")
    end
  end

  context "when creating a subscriber list with no tags or links" do
    context "and a document_type is provided" do
      it "returns a 201" do
        create_subscriber_list(document_type: "travel_advice")

        expect(response.status).to eq(201)
      end
    end

    context "and no document_type is provided" do
      it "returns a 422" do
        create_subscriber_list

        expect(response.status).to eq(422);
        expect(response.body).to match(/Must have either a document_type, tags or links/)
      end
    end
  end

  def create_subscriber_list(tags: {}, links: {}, document_type: nil)
    payload = {
      title: "This is a sample title",
      gov_delivery_id: "UKGOVUK_1234",
      tags: tags,
      links: links,
    }

    payload.merge!(document_type: document_type) if document_type
    request_body = JSON.dump(payload)

    post "/subscriber-lists", request_body, json_headers
  end
end
