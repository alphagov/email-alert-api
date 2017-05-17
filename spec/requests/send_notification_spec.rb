require "rails_helper"
require 'sidekiq/testing'

RSpec.describe "Sending a notification", type: :request do
  before do
    Sidekiq::Testing.fake!
    @gov_delivery = double(:gov_delivery, send_bulletin: nil)
    allow(Services).to receive(:gov_delivery).and_return(@gov_delivery)
  end

  after do
    Sidekiq::Worker.clear_all
  end

  it "returns a 202" do
    send_notification({ topics: ["oil-and-gas/licensing"] })

    expect(response.status).to eq(202)
  end

  it "kicks off a notification job" do
    expect {
      send_notification(topics: ["oil-and-gas/licensing"])
    }.to change{NotificationWorker.jobs.count}.from(0).to(1)
  end

  it "sends notifications for the right subscriber lists" do
    relevant_list_ids, irrelevant_list_ids = create_many_lists

    send_notification({
      topics: ["oil-and-gas/licensing"],
      organisations: ["environment-agency", "hm-revenue-customs"]
    })

    NotificationWorker.drain

    expect(@gov_delivery).to have_received(:send_bulletin)
      .with(
        relevant_list_ids,
        "This is a sample subject",
        "Here is some body copy<span data-govuk-request-id=\"\"></span>",
        {},
      )
  end

  it "sends notifications with options if given" do
    relevant_list_ids, irrelevant_list_ids = create_many_lists

    send_notification({
      topics: ["oil-and-gas/licensing"],
      organisations: ["environment-agency", "hm-revenue-customs"]
    },
    {
      from_address_id: "12345",
      urgent: true,
      header: "foo",
      footer: "bar",
    })

    NotificationWorker.drain

    expect(@gov_delivery).to have_received(:send_bulletin)
      .with(
        relevant_list_ids,
        "This is a sample subject",
        "Here is some body copy<span data-govuk-request-id=\"\"></span>",
        {
          "from_address_id" => "12345",
          "urgent" => true,
          "header" => "foo",
          "footer" => "bar"
        }
      )
  end

  it "doesn't send notifications if there's no lists" do
    send_notification({
      topics: ["oil-and-gas/licensing"],
      organisations: ["environment-agency", "hm-revenue-customs"]
    })

    NotificationWorker.drain

    expect(@gov_delivery).not_to have_received(:send_bulletin)
  end

  def create_many_lists
    duplicate_topic_id = "UKGOVUK_DUPLICATE"

    all_match = create(:subscriber_list,
      gov_delivery_id: duplicate_topic_id,
      tags: {
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"]
      }
    )

    partial_type_match = create(:subscriber_list, tags: {
      topics: ["oil-and-gas/licensing"],
      browse_pages: ["tax/vat"]
    })

    full_type_partial_tag_match = create(:subscriber_list,
      gov_delivery_id: duplicate_topic_id,
      tags: {
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency"]
      }
    )

    full_type_no_tag_match = create(:subscriber_list, tags: {
      topics: ["schools-colleges/administration-finance"],
      organisations: ["department-for-education"]
    })

    full_type_but_empty = create(:subscriber_list, tags: {
      topics: [],
      organisations: ["environment-agency", "hm-revenue-customs"]
    })

    relevant_lists = [
      all_match,
      full_type_partial_tag_match
    ]

    irrelevant_lists = [
      partial_type_match,
      full_type_no_tag_match,
      full_type_but_empty
    ]

    return [
      relevant_lists.map(&:gov_delivery_id).uniq,
      irrelevant_lists.map(&:gov_delivery_id).uniq
    ]
  end

  def send_notification(tags, options = {})
    request_body = JSON.dump({
      subject: "This is a sample subject",
      body: "Here is some body copy",
      tags: tags,
    }.merge(options))

    post "/notifications", params: request_body, headers: json_headers
  end
end
