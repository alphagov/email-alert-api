RSpec.describe "Creating subscriber lists", type: :request do
  scenario "creating and looking up subscriber lists" do
    login_with(%w[internal_app status_updates])

    params = { title: "Example", tags: {}, links: { person: { any: %w[test-123] } } }

    lookup_subscriber_list_by_slug("example", expected_status: 404)
    lookup_subscriber_list(params, expected_status: 404)

    create_subscriber_list(links: { person: { any: %w[test-123] } })

    lookup_subscriber_list_by_slug("example", expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(params)

    lookup_subscriber_list(params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(params)
  end

  scenario "creating and looking up legacy subscriber lists" do
    login_with(%w[internal_app status_updates])

    legacy_params = { title: "example", tags: {}, links: { person: %w[test-123] } }
    new_params = { title: "example", tags: {}, links: { person: { any: %w[test-123] } } }

    lookup_subscriber_list_by_slug("example", expected_status: 404)
    lookup_subscriber_list(legacy_params, expected_status: 404)

    create_subscriber_list(title: "example", links: { person: %w[test-123] })

    lookup_subscriber_list_by_slug("example", expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(new_params)

    lookup_subscriber_list(new_params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(new_params)

    lookup_subscriber_list(legacy_params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(new_params)
  end

  def lookup_subscriber_list_by_slug(slug, expected_status: 200)
    get "/subscriber-lists/#{slug}"
    expect(response.status).to eq(expected_status)
    data.dig(:subscriber_list, :id)
  end

  def lookup_subscriber_list(params, expected_status: 200)
    get "/subscriber-lists", params:, headers: json_headers
    expect(response.status).to eq(expected_status)
  end
end
