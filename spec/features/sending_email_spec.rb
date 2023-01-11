RSpec.describe "Sending an email", type: :request do
  scenario "sending an email for a content change" do
    login_with_internal_app

    subscriber_list = create_subscriber_list
    subscribe_to_subscriber_list(subscriber_list[:id])
    create_content_change

    email_data = expect_an_email_was_sent(
      subject: "Update from GOV.UK for: Title",
      address: "test@test.com",
    )

    body = email_data.dig(:personalisation, :body)
    expect(body).to include("Description")
    expect(body).to include("gov.uk/base-path")
    expect(body).to include("Change note")
    expect(body).to include("12:00am, 1 January 2017")
    expect(body).to include("[Unsubscribe](http://www.dev.gov.uk/email/unsubscribe")
    expect(body).to include("gov.uk/email/manage/authenticate")
  end
end
