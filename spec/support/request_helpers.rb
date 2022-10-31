module RequestHelpers
  def create_subscriber_list(overrides = {})
    params = { title: "Example", tags: {}, links: {} }.merge(overrides)
    post "/subscriber-lists", params: params.to_json, headers: json_headers
    expect(response.status).to eq(200)
    data[:subscriber_list]
  end

  def subscribe_to_subscriber_list(subscriber_list_id, expected_status: 200,
                                   address: "test@test.com", frequency: "immediately")
    params = {
      subscriber_list_id: subscriber_list_id,
      address: address,
      frequency: frequency,
    }
    post "/subscriptions", params: params.to_json, headers: json_headers
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

    post "/content-changes", params: params.to_json, headers: json_headers
    expect(response.status).to eq(202)
  end

  def send_status_update(reference: SecureRandom.uuid,
                         status: "delivered",
                         to: "test.user@example.com",
                         expected_status: 204)
    params = { reference: reference, status: status, to: to }
    post "/status-updates", params: params.to_json, headers: json_headers
    expect(response.status).to eq(expected_status)
  end

  def data(body = response.body)
    JSON.parse(body).deep_symbolize_keys
  end

  def json_headers
    {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json",
      "HTTP_GOVUK_REQUEST_ID" => "request-id",
    }
  end
end
