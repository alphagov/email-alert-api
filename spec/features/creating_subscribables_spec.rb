RSpec.describe "Creating subscribables", type: :request do
  before do
    stub_govdelivery("UKGOVUK_1234")
  end

  scenario "creating and looking up subscribables" do
    params = { title: "Example", tags: {}, links: { person: ["test-123"] } }

    get "/subscriber-lists", params: params, headers: JSON_HEADERS
    expect(response.status).to eq(404)

    get "/subscribables/UKGOVUK_1234"
    expect(response.status).to eq(404)

    create_subscribable(links: { person: ["test-123"] })

    get "/subscriber-lists", params: params, headers: JSON_HEADERS
    expect(response.status).to eq(200)
    expect(data.fetch(:subscriber_list)).to include(params)

    gov_delivery_id = data.dig(:subscriber_list, :gov_delivery_id)
    expect(gov_delivery_id).to eq("UKGOVUK_1234")

    get "/subscribables/UKGOVUK_1234"
    expect(response.status).to eq(200)
    expect(data.fetch(:subscribable)).to include(params)
  end
end
