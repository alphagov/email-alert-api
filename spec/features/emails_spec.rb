RSpec.describe "Sending an email", type: :request do
  before do
    stub_notify
  end

  scenario do
    params = {
      body: 'Description',
      subject: 'Update from GOV.UK',
      address: 'test@test.com'
    }

    post '/emails', params: params.to_json, headers: JSON_HEADERS

    email_data = expect_an_email_was_sent

    address = email_data.dig(:email_address)
    subject = email_data.dig(:personalisation, :subject)
    body = email_data.dig(:personalisation, :body)

    expect(address).to eq("test@test.com")
    expect(subject).to eq("Update from GOV.UK")

    expect(body).to include("Description")
  end
end
