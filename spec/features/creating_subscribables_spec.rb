RSpec.describe "Creating subscribables", type: :request do
  scenario "creating and looking up subscribables" do
    login_with(%w(internal_app status_updates))

    params = { title: "Example", tags: {}, links: { person: { any: ["test-123"] } } }

    lookup_subscribable("example", expected_status: 404)
    lookup_subscriber_list(params, expected_status: 404)

    create_subscribable(links: { person: { any: ["test-123"] } })

    lookup_subscribable("example", expected_status: 200)
    expect(data.fetch(:subscribable)).to include(params)

    lookup_subscriber_list(params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(params)

    gov_delivery_id = data.dig(:subscriber_list, :gov_delivery_id)
    expect(gov_delivery_id).to eq("example")
  end
end
