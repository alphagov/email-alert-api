RSpec.describe "Creating subscriber lists", type: :request do
  scenario "creating and looking up subscriber lists" do
    login_with(%w(internal_app status_updates))

    params = { title: "Example", tags: {}, links: { person: { any: ["test-123"] } } }

    lookup_subscriber_list_by_slug("example", expected_status: 404)
    lookup_subscriber_list(params, expected_status: 404)

    create_subscriber_list(links: { person: { any: ["test-123"] } })

    lookup_subscriber_list_by_slug("example", expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(params)

    lookup_subscriber_list(params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(params)

    gov_delivery_id = data.dig(:subscriber_list, :gov_delivery_id)
    expect(gov_delivery_id).to eq("example")
  end

  scenario "creating and looking up subscriber lists where the facets are joined with or" do
    login_with(%w(internal_app status_updates))

    params = { title: "Example", tags: {}, links: { person: { any: ["test-123"] } }, combine_mode: "or" }

    lookup_subscriber_list_by_slug("example", expected_status: 404)
    lookup_subscriber_list(params, expected_status: 404)

    create_or_joined_facet_subscriber_list(links: { person: { any: ["test-123"] } })

    lookup_subscriber_list_by_slug("example", expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(params.except(:combine_mode))

    lookup_subscriber_list(params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(params.except(:combine_mode))

    gov_delivery_id = data.dig(:subscriber_list, :gov_delivery_id)
    expect(gov_delivery_id).to eq("example")
  end

  scenario "creating and looking up subscriber_list and or_joined_facet_subscriber_list with same facets" do
    login_with(%w(internal_app status_updates))
    links_params = { person: { any: ["test-123"] } }
    facets = { title: "Example", tags: {}, links: links_params }

    subscriber_list_params = facets.merge(combine_mode: "")
    or_joined_facet_subscriber_list_params = facets.merge(combine_mode: "or")

    lookup_subscriber_list(subscriber_list_params, expected_status: 404)
    lookup_subscriber_list(or_joined_facet_subscriber_list_params, expected_status: 404)

    create_subscriber_list(links: links_params)

    lookup_subscriber_list(subscriber_list_params, expected_status: 200)
    lookup_subscriber_list(or_joined_facet_subscriber_list_params, expected_status: 404)

    create_or_joined_facet_subscriber_list(links: links_params)

    lookup_subscriber_list(subscriber_list_params, expected_status: 200)
    lookup_subscriber_list(or_joined_facet_subscriber_list_params, expected_status: 200)
  end

  scenario "creating and looking up subscriber_list and or_joined_facet_subscriber_list with the same params without combine_mode param" do
    # It will simply return the first subscriber_list of any type, in this case, the or_joined_facet_subscriber_list
    login_with(%w(internal_app status_updates))
    params = { title: "Example", tags: {}, links: { person: { any: ["test-123"] } } }

    lookup_subscriber_list(params, expected_status: 404)

    create_subscriber_list(links: { person: { any: ["test-123"] } })
    or_joined_facet_subscriber_list_id = create_or_joined_facet_subscriber_list(links: { person: { any: ["test-123"] } })

    lookup_subscriber_list(params, expected_status: 200)
    assert_equal or_joined_facet_subscriber_list_id, data[:subscriber_list][:id]
  end

  scenario "creating and looking up legacy subscriber lists" do
    login_with(%w(internal_app status_updates))

    legacy_params = { title: "example", tags: {}, links: { person: ["test-123"] } }
    new_params = { title: "example", tags: {}, links: { person: { any: ["test-123"] } } }

    lookup_subscriber_list_by_slug("example", expected_status: 404)
    lookup_subscriber_list(legacy_params, expected_status: 404)

    create_subscriber_list(title: "example", links: { person: ["test-123"] })

    lookup_subscriber_list_by_slug("example", expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(new_params)

    lookup_subscriber_list(new_params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(new_params)

    lookup_subscriber_list(legacy_params, expected_status: 200)
    expect(data.fetch(:subscriber_list)).to include(new_params)

    gov_delivery_id = data.dig(:subscriber_list, :gov_delivery_id)
    expect(gov_delivery_id).to eq("example")
  end
end
