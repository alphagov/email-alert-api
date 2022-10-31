RSpec.describe "Login verify email", type: :request do
  include TokenHelpers

  let(:address) { "test@example.com" }
  let!(:subscriber) { create(:subscriber, address:) }
  let(:destination) { "/authenticate" }

  scenario "successful auth token" do
    login_with_internal_app

    post "/subscribers/auth-token",
         params: {
           address:,
           destination:,
         }

    email_data = expect_an_email_was_sent(
      address: "test@example.com",
      subject: "Change your GOV.UK email preferences",
    )

    expect(response.status).to be 201

    body = email_data.dig(:personalisation, :body)
    expect(body).to include("http://www.dev.gov.uk#{destination}?token=")

    expect(decrypt_token_from_link(body)).to eq(
      "subscriber_id" => subscriber.id,
    )
  end
end
