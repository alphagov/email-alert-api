RSpec.describe "Sending an email", type: :request do
  before do
    stub_govdelivery("UKGOVUK_1234")
    stub_notify
  end

  scenario "sending an email for a subscription to a subscribable" do
    subscribable_id = create_subscribable
    subscribe_to_subscribable(subscribable_id)
    create_content_change
    email_data = expect_an_email_was_sent

    address = email_data.dig(:email_address)
    subject = email_data.dig(:personalisation, :subject)
    body = email_data.dig(:personalisation, :body)

    expect(address).to eq("test@test.com")
    expect(subject).to eq("GOV.UK Update - Title")

    expect(body).to include("Change note: Description")
    expect(body).to include("gov.uk/base-path")
    expect(body).to include("Updated on 12:00 am, 1 January 2017")

    expect(body).to include("Unsubscribe from 'Example'")
    expect(body).to include("gov.uk/email/unsubscribe/")
  end
end
