RSpec.describe "Weekly digests", type: :request do
  let(:list_organisation_id) { "0eb5d0f0-d384-4f27-9da8-3f9e9b22a820" }
  let(:list_two_taxon_id) { "6416e4e0-c0c1-457a-8337-4bf8ed9d5f80" }

  let(:subscriber_list_one) do
    create_subscriber_list(
      title: "Subscriber list one",
      links: {
        organisations: { any: [list_organisation_id] },
      },
    )
  end

  let(:subscriber_list_two) do
    create_subscriber_list(
      title: "Subscriber list two",
      links: {
        taxon_tree: { all: [list_two_taxon_id] },
      },
    )
  end

  before do
    login_with_internal_app
  end

  scenario "single list" do
    subscribe_to_subscriber_list(
      subscriber_list_one[:id],
      frequency: Frequency::WEEKLY,
    )

    # publish two items to each list
    travel_to(Time.zone.parse("2017-01-01 09:30")) do
      create_content_change(
        title: "Title one",
        content_id: SecureRandom.uuid,
        description: "Description one",
        change_note: "Change note one",
        public_updated_at: "2017-01-01 10:00:00",
        links: {
          organisations: [list_organisation_id],
        },
      )
    end

    travel_to(Time.zone.parse("2017-01-07 10:00")) do
      WeeklyDigestInitiatorJob.new.perform
      Sidekiq::Job.drain_all
    end

    email_data = expect_an_email_was_sent(
      subject: "Weekly update from GOV.UK for: Subscriber list one",
    )

    body = email_data.dig(:personalisation, :body)
    expect(body).to include("Title one")
    expect(body).to include("gov.uk/base-path")
    expect(body).to include("Change note one")
    expect(body).to include("Description one")
    expect(body).to include("10:00am, 1 January 2017")
    expect(body).to include("[Unsubscribe](http://www.dev.gov.uk/email/unsubscribe")
    expect(body).to include("gov.uk/email/manage/authenticate")
  end

  scenario "multiple lists" do
    subscribe_to_subscriber_list(
      subscriber_list_one[:id],
      frequency: Frequency::WEEKLY,
    )

    subscribe_to_subscriber_list(
      subscriber_list_two[:id],
      frequency: Frequency::WEEKLY,
    )

    travel_to(Time.zone.parse("2017-01-01 09:30")) do
      create_content_change(links: { organisations: [list_organisation_id] })
    end

    travel_to(Time.zone.parse("2017-01-04 09:32")) do
      create_content_change(links: { taxon_tree: [list_two_taxon_id] })
    end

    travel_to(Time.zone.parse("2017-01-07 10:00")) do
      WeeklyDigestInitiatorJob.new.perform
      Sidekiq::Job.drain_all
    end

    expect_an_email_was_sent(
      subject: "Weekly update from GOV.UK for: Subscriber list one",
    )

    expect_an_email_was_sent(
      subject: "Weekly update from GOV.UK for: Subscriber list two",
    )
  end
end
