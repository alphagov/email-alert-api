RSpec.describe "Sending an email", type: :request do
  scenario "sending an email for a content change" do
    login_with_internal_app

    subscriber_list_id = create_subscriber_list
    subscribe_to_subscriber_list(subscriber_list_id)
    create_content_change
    email_data = expect_an_email_was_sent

    address = email_data.dig(:email_address)
    subject = email_data.dig(:personalisation, :subject)
    body = email_data.dig(:personalisation, :body)

    expect(address).to eq("test@test.com")
    expect(subject).to eq("Update from GOV.UK for: Title")

    expect(body).to include("Description")
    expect(body).to include("gov.uk/base-path")
    expect(body).to include("Change note")
    expect(body).to include("12:00am, 1 January 2017")
    expect(body).to include("[Unsubscribe](http://www.dev.gov.uk/email/unsubscribe")
    expect(body).to include("gov.uk/email/manage/authenticate?address=")
  end

  scenario "sending an email for a message" do
    login_with_internal_app

    subscriber_list_id = create_subscriber_list(
      tags: { brexit_checklist_criteria: { any: %w[eu-national] } },
    )
    subscribe_to_subscriber_list(subscriber_list_id)
    create_message(
      criteria_rules: [{ type: "tag", key: "brexit_checklist_criteria", value: "eu-national" }],
    )
    email_data = expect_an_email_was_sent

    address = email_data.dig(:email_address)
    subject = email_data.dig(:personalisation, :subject)
    body = email_data.dig(:personalisation, :body)

    expect(address).to eq("test@test.com")
    expect(subject).to eq("Update from GOV.UK – Title")

    expect(body).to include("Body")
    expect(body).to include("View, unsubscribe or change the frequency of your subscriptions")
    expect(body).to include("gov.uk/email/manage/authenticate?address=")
  end
end
