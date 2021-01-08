RSpec.describe "Create an auth token", type: :request do
  include TokenHelpers

  around do |example|
    Sidekiq::Testing.inline! do
      freeze_time { example.run }
    end
  end

  let(:address) { "test@example.com" }
  let!(:subscriber) { create(:subscriber, address: address) }
  let(:destination) { "/authenticate" }

  scenario "successful auth token" do
    login_with_internal_app

    post "/subscribers/auth-token",
         params: {
           address: address,
           destination: destination,
         }

    email_data = expect_an_email_was_sent(
      address: "test@example.com",
      subject: "Manage your GOV.UK email subscriptions",
    )

    expect(response.status).to be 201

    body = email_data.dig(:personalisation, :body)
    expect(body).to include("http://www.dev.gov.uk#{destination}?token=")

    token = URI.decode_www_form_component(
      body.match(/token=([^&\n]+)/)[1],
    )

    expect(decrypt_and_verify_token(token)).to eq(
      "subscriber_id" => subscriber.id,
    )
  end
end
