RSpec.describe "Sending an email", type: :request do
  before do
    stub_notify
  end

  scenario "sending an email for a subscription to a subscriber_list" do
    login_with_internal_app

    subscriber_list_id = create_subscriber_list
    subscribe_to_subscriber_list(subscriber_list_id)
    create_content_change
    email_data = expect_an_email_was_sent

    address = email_data.dig(:email_address)
    subject = email_data.dig(:personalisation, :subject)
    body = email_data.dig(:personalisation, :body)

    expect(address).to eq("test@test.com")
    expect(subject).to eq("Update from GOV.UK – Title")

    expect(body).to include("Description")
    expect(body).to include("gov.uk/base-path")
    expect(body).to include("Change note")
    expect(body).to include("12:00am, 1 January 2017")
    expect(body).to include("View, unsubscribe or change the frequency of your subscriptions")
    expect(body).to include("gov.uk/email/authenticate?address=")
  end
end
