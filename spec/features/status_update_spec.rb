RSpec.describe "Status updates", type: :request do
  before do
    login_with(%w[internal_app status_updates])
    subscriber_list = create_subscriber_list
    subscribe_to_subscriber_list(subscriber_list[:id])
    create_content_change
    @email_data = expect_an_email_was_sent
  end

  scenario "successful delivery" do
    reference = @email_data.fetch(:reference)
    send_status_update(reference:, expected_status: 204)
    send_status_update(reference: nil, expected_status: 400)
  end

  scenario "permanent failure" do
    send_status_update(status: "permanent-failure",
                       to: @email_data.fetch(:email_address),
                       expected_status: 204)

    clear_any_requests_that_have_been_recorded!
    3.times { create_content_change }
    expect_an_email_was_not_sent
  end
end
