RSpec.describe "Creating subscriber lists for single content items", type: :request do
  scenario "creating and querying subscriber lists" do
    given_i_am_authenticated
    i_can_create_a_subscriber_list_with_a_content_id_param
    i_can_query_an_existing_subscriber_list_with_a_content_id_param
    i_recieve_404_when_querying_a_content_id_that_has_no_subscriber_list
  end

  def i_can_query_an_existing_subscriber_list_with_a_content_id_param
    response = lookup_subscriber_list_by_content_id("7c615f50-d48e-47a9-82be-6181559198ed")
    content_id_is_in_returned_payload(response, "7c615f50-d48e-47a9-82be-6181559198ed")
  end

  def i_can_create_a_subscriber_list_with_a_content_id_param
    response = create_subscriber_list({ content_id: "7c615f50-d48e-47a9-82be-6181559198ed" })
    content_id_is_in_returned_payload(response, "7c615f50-d48e-47a9-82be-6181559198ed")
  end

  def i_recieve_404_when_querying_a_content_id_that_has_no_subscriber_list
    lookup_subscriber_list_by_content_id("4610043b-2787-4933-bcc1-7e2e02685ab6", expected_status: 404)
  end

  def content_id_is_in_returned_payload(response, content_id)
    expect(response).to include(content_id:)
  end

  def given_i_am_authenticated
    login_with(%w[internal_app status_updates])
  end

  def parameters_with_content_id
    { title: "Example", content_id: "7c615f50-d48e-47a9-82be-6181559198ed", tags: {}, links: {} }
  end

  def lookup_subscriber_list_by_content_id(content_id, expected_status: 200)
    get "/subscriber-lists?content_id=#{content_id}"
    expect(response.status).to eq(expected_status)
    data[:subscriber_list]
  end
end
