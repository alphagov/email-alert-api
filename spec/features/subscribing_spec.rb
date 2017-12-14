RSpec.describe "Subscribing to a subscribable", type: :request do
  before do
    stub_govdelivery("UKGOVUK_1234")
  end

  scenario "subscribing to a subscribable" do
    subscribable_id = create_subscribable

    params = { subscribable_id: subscribable_id, address: "test@test.com" }
    post "/subscriptions", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(201)

    params = { subscribable_id: subscribable_id, address: "test@test.com" }
    post "/subscriptions", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(200)

    params = { subscribable_id: "missing", address: "test@test.com" }
    post "/subscriptions", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(404)
  end
end
