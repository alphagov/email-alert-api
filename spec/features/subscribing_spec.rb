RSpec.describe "Subscribing", type: :request do
  include TokenHelpers

  let(:address) { "test@example.com" }
  let(:frequency) { "immediately" }
  let(:subscriber_list) { create_subscriber_list }

  before do
    login_with_internal_app
  end

  scenario "successful subscription" do
    post "/subscriptions/auth-token",
         params: {
           address:,
           topic_id: subscriber_list[:slug],
           frequency:,
         }

    email_data = expect_an_email_was_sent(
      address: "test@example.com",
      subject: "Confirm that you want to get emails from GOV.UK",
    )

    body = email_data.dig(:personalisation, :body)
    expect(body).to include("http://www.dev.gov.uk/email/subscriptions/authenticate?token=")

    expect(decrypt_token_from_link(body)).to eq(
      "address" => address,
      "frequency" => frequency,
      "topic_id" => subscriber_list[:slug],
    )

    # It's expected that the frontend app will interpret the data in
    # the token in order to make this call.
    subscribe_to_subscriber_list(
      subscriber_list[:id],
      address:,
      frequency:,
      expected_status: 200,
    )

    expect_an_email_was_sent(
      subject: /You’ve subscribed to/,
      address:,
    )
  end

  scenario "repeat subscription" do
    subscribe_to_subscriber_list(subscriber_list[:id], expected_status: 200)
    subscribe_to_subscriber_list(subscriber_list[:id], expected_status: 200)
  end
end
