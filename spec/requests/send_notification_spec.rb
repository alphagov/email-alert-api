require "rails_helper"
require 'sidekiq/testing'

RSpec.describe "Sending a notification", type: :request do
  before do
    Sidekiq::Testing.fake!
    @original_gov_delivery = EmailAlertAPI.services(:gov_delivery)
    @gov_delivery = double(:gov_delivery, send_bulletin: nil)
    EmailAlertAPI.services(:gov_delivery, @gov_delivery)
  end

  after do
    Sidekiq::Worker.clear_all
    EmailAlertAPI.services(:gov_delivery, @original_gov_delivery)
  end

  it "returns a 202" do
    send_notification(topics: ["oil-and-gas/licensing"])

    expect(response.status).to eq(202)
  end

  it "kicks off a notification job" do
    expect {
      send_notification(topics: ["oil-and-gas/licensing"])
    }.to change{NotificationWorker.jobs.count}.from(0).to(1)
  end

  it "sends notifications for the right subscriber lists" do
    relevant_list_ids, irrelevant_list_ids = create_many_lists

    send_notification(
      topics: ["oil-and-gas/licensing"],
      organisations: ["environment-agency", "hm-revenue-customs"]
    )

    NotificationWorker.drain

    expect(@gov_delivery).to have_received(:send_bulletin)
      .with(
        relevant_list_ids,
        "This is a sample subject",
        "Here is some body copy"
      )
  end

  def create_many_lists
    all_match = FactoryGirl.create(:subscriber_list, tags: {
      topics: ["oil-and-gas/licensing"],
      organisations: ["environment-agency", "hm-revenue-customs"]
    })

    partial_type_match = FactoryGirl.create(:subscriber_list, tags: {
      topics: ["oil-and-gas/licensing"],
      browse_pages: ["tax/vat"]
    })

    full_type_partial_tag_match = FactoryGirl.create(:subscriber_list, tags: {
      topics: ["oil-and-gas/licensing"],
      organisations: ["environment-agency"]
    })

    full_type_no_tag_match = FactoryGirl.create(:subscriber_list, tags: {
      topics: ["schools-colleges/administration-finance"],
      organisations: ["department-for-education"]
    })

    full_type_but_empty = FactoryGirl.create(:subscriber_list, tags: {
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
      relevant_lists.map(&:gov_delivery_id),
      irrelevant_lists.map(&:gov_delivery_id)
    ]
  end

  def send_notification(tags)
    post "/notifications", {
      subject: "This is a sample subject",
      body: "Here is some body copy",
      tags: tags
    }
  end
end
