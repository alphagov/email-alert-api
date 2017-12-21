RSpec.describe "Failing to deliver an email via Notify (technical failure)", type: :request do
  before do
    stub_govdelivery("UKGOVUK_1234")
    stub_notify
  end

  scenario "failing the healthcheck if delivery failed for a technical reason" do
    login_with(%w(internal_app status_updates))

    subscribable_id = create_subscribable
    subscribe_to_subscribable(subscribable_id)
    create_content_change
    email_data = expect_an_email_was_sent

    check_health_of_the_app
    expect(data.fetch(:status)).to eq("ok")

    reference = email_data.fetch(:reference)
    send_status_update(reference, "technical-failure", expected_status: 204)

    check_health_of_the_app
    expect(data.fetch(:status)).to eq("critical")

    clear_any_requests_that_have_been_recorded!
    create_content_change
    expect_an_email_was_sent
  end
end
