require "rails_helper"

RSpec.describe TopicMatchesController, type: :controller do
  it "returns topics, enabled, disabled for a subscriber list query" do
    FactoryGirl.create(
      :subscriber_list,
      links: { organisation: ["content-id-123"] },
      gov_delivery_id: "TOPIC_123",
    )

    params = { links: { organisation: ["content-id-123"] } }
    get :show, params: params, format: :json
    data = JSON.parse(response.body).symbolize_keys

    expect(data).to eq(
      topics: ["TOPIC_123"],
      enabled: ["TOPIC_123"],
      disabled: [],
    )
  end

  it "returns empty arrays if the query returns nothing" do
    get :show, params: {}, format: :json
    data = JSON.parse(response.body).symbolize_keys
    expect(data).to eq(topics: [], enabled: [], disabled: [])
  end
end
