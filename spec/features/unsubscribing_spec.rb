RSpec.describe "Unsubscribing from a subscribable", type: :request do
  before do
    stub_govdelivery("UKGOVUK_1234")
    stub_notify
  end

  scenario "unsubscribing from an email uuid, then no longer receiving emails" do
    subscribable_id = create_subscribable
    subscribe_to_subscribable(subscribable_id)
    create_content_change
    email_data = expect_an_email_was_sent

    uuid = extract_unsubscribe_uuid(email_data)
    post "/unsubscribe/#{uuid}"
    expect(response.status).to eq(204)

    clear_any_requests_that_have_been_recorded!

    create_content_change
    expect_an_email_was_not_sent

    post "/unsubscribe/#{uuid}"
    expect(response.status).to eq(404)

    post "/unsubscribe/missing"
    expect(response.status).to eq(404)
  end
end
