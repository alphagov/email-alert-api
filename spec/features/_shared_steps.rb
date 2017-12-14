module SharedSteps
  def stub_govdelivery(gov_delivery_id)
    body = "<topic><to-param>#{gov_delivery_id}</to-param></topic>"
    stub_request(:post, /govdelivery/).to_return(body: body)
  end

  def stub_notify
    allow_any_instance_of(DeliveryRequestService)
      .to receive(:provider_name).and_return("notify")

    body = {}.to_json
    stub_request(:post, /fake-notify/).to_return(body: body)
  end

  def create_subscribable(overrides = {})
    params = { title: "Example", tags: {}, links: {} }.merge(overrides)
    post "/subscriber-lists", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(201)
    data.dig(:subscriber_list, :id)
  end

  def subscribe_to_subscribable(subscribable_id)
    params = { subscribable_id: subscribable_id, address: "test@test.com" }
    post "/subscriptions", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(201)
  end

  def create_content_change(overrides = {})
    params = {
      base_path: "/base-path",
      content_id: "00000000-0000-0000-0000-000000000000",
      change_note: "Change note",
      description: "Description",
      document_type: "document_type",
      email_document_supertype: "email_supertype",
      government_document_supertype: "government_supertype",
      public_updated_at: "2017-01-01 00:00:00",
      publishing_app: "publishing-app",
      title: "Title",
      links: {},
    }.merge(overrides)

    post "/notifications", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(202)
  end

  def expect_an_email_was_sent
    request_data = nil
    expectation = ->(request) { request_data = data(request.body) }
    expect(a_request(:post, /fake-notify/).with(&expectation)).to have_been_made
    request_data
  end

  def expect_an_email_was_not_sent
    expect(a_request(:post, /fake-notify/)).not_to have_been_made
  end

  def extract_unsubscribe_uuid(email_data)
    body = email_data.dig(:personalisation, :body)
    body[%r{/unsubscribe/(.*)\?}, 1]
  end

  def clear_any_requests_that_have_been_recorded!
    WebMock::RequestRegistry.instance.reset!
  end
end
