module RequestHelpers
  def stub_notify
    allow_any_instance_of(DeliveryRequestService)
      .to receive(:provider_name).and_return("notify")

    body = {}.to_json
    stub_request(:post, /fake-notify/).to_return(body: body)
  end

  def check_health_of_the_app
    get "/healthcheck"
    expect(response.status).to eq(200)
  end

  def create_subscriber_list(overrides = {})
    params = { title: "Example", tags: {}, links: {} }.merge(overrides)
    post "/subscriber-lists", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(201)
    data.dig(:subscriber_list, :id)
  end

  def lookup_subscriber_list_by_slug(slug, expected_status: 200)
    get "/subscriber-lists/#{slug}"
    expect(response.status).to eq(expected_status)
    data.dig(:subscriber_list, :id)
  end

  def lookup_subscriber_list(params, expected_status: 200)
    get "/subscriber-lists", params: params, headers: JSON_HEADERS
    expect(response.status).to eq(expected_status)
  end

  def subscribe_to_subscriber_list(subscriber_list_id, expected_status: 201,
    address: "test@test.com", frequency: "immediately")
    params = {
      subscriber_list_id: subscriber_list_id,
      address: address,
      frequency: frequency,
    }
    post "/subscriptions", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(expected_status)
    expect_a_subscription_confirmation_email_was_sent
  end

  def unsubscribe_from_subscriber_list(id, expected_status: 204)
    post "/unsubscribe/#{id}"
    expect(response.status).to eq(expected_status)
  end

  def create_content_change(overrides = {})
    params = {
      base_path: "/base-path",
      content_id: SecureRandom.uuid,
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

    post "/content-changes", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(202)
  end

  def create_message(overrides = {})
    params = {
      sender_message_id: SecureRandom.uuid,
      title: "Title",
      body: "Body",
      criteria_rules: [
        {
          type: "tag",
          key: "brexit_checklist_criteria",
          value: "eu-national",
        },
      ],
    }.merge(overrides)

    post "/messages", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(202)
  end

  def send_status_update(reference, status, completed_at, sent_at, expected_status: 204)
    params = { reference: reference, status: status, completed_at: completed_at, sent_at: sent_at }
    post "/status-updates", params: params.to_json, headers: JSON_HEADERS
    expect(response.status).to eq(expected_status)
  end

  def expect_an_email_was_sent
    request_data = nil
    expectation = ->(request) { request_data = data(request.body) }
    expect(a_request(:post, /fake-notify/).with(&expectation)).to have_been_made.at_least_once
    request_data
  end

  def expect_an_email_was_not_sent
    expect(a_request(:post, /fake-notify/)).not_to have_been_made
  end

  def expect_a_subscription_confirmation_email_was_sent
    email_data = expect_an_email_was_sent
    subject = email_data.fetch(:personalisation).fetch(:subject)
    expect(subject).to match(/You've subscribed to/)
  end

  def extract_unsubscribe_id(email_data)
    body = email_data.dig(:personalisation, :body)
    body[%r{/unsubscribe/(.*)\)}, 1]
  end

  def data(body = response.body)
    JSON.parse(body).deep_symbolize_keys
  end

  def clear_any_requests_that_have_been_recorded!
    WebMock::RequestRegistry.instance.reset!
  end
end
