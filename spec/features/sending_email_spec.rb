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
    expect(subject).to eq("GOV.UK update – Title")

    expect(body).to include("Description")
    expect(body).to include("gov.uk/base-path")
    expect(body).to include("12:00am, 1 January 2017: Change note")
    expect(body).to include("[Unsubscribe from ‘Example’]")
    expect(body).to include("gov.uk/email/unsubscribe/")
  end

  scenario "sending an email for a subscription to an or_joined_facet_subscriber_list" do
    login_with_internal_app
    facets = {
        links: {
            topics: { all: %w(topic_one) },
            organisations: { all: %w(organisation_1) }
        }
    }
    and_joined_subscriber_list_id = create_subscriber_list(facets.merge(title: "And joined list"))
    or_joined_subscriber_list_id = create_or_joined_facet_subscriber_list(facets.merge(title: "Or joined list"))
    subscribe_to_subscriber_list(or_joined_subscriber_list_id)
    subscribe_to_subscriber_list(and_joined_subscriber_list_id)
    create_content_change(links: { topics: %w(topic_one) })
    email_data = expect_an_email_was_sent

    address = email_data.dig(:email_address)
    subject = email_data.dig(:personalisation, :subject)
    body = email_data.dig(:personalisation, :body)

    expect(address).to eq("test@test.com")
    expect(subject).to eq("GOV.UK update – Title")

    expect(body).to include("Description")
    expect(body).to include("gov.uk/base-path")
    expect(body).to include("12:00am, 1 January 2017: Change note")
    expect(body).to include("[Unsubscribe from ‘Or joined list’]")
    expect(body).to include("gov.uk/email/unsubscribe/")
  end
end
