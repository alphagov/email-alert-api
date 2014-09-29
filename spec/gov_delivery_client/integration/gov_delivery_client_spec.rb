require "spec_helper"
require "webmock"
require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/gov_delivery_client/integration/fixtures/vcr_cassettes"
  c.hook_into :webmock# or :fakeweb
end

require "gov_delivery_client"

RSpec.describe GovDeliveryClient do
  subject(:client) {
    GovDeliveryClient.create_client(
      protocol: "https",
      hostname: "stage-api.govdelivery.com",
      account_code: "UKGOVUK",
      username: "gov-delivery+staging@digital.cabinet-office.gov.uk",
      password: "nottherealpassword",
      subscription_link_template: "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=%{topic_id}",
    )
  }

  it "creates a topic" do
    topic = nil

    # If you wish to delete the fixture and re-record this request you must
    # * first TEMPORARILY replace the password above with the real one
    # * record the request
    # * change it back to the dummy value
    # * edit the VCR cassette (YAML file) and replace with the dummy password
    #
    # Finally, really make sure you are not publicly exposing the real staging
    # password!
    VCR.use_cassette("create_topic") do
      topic = client.create_topic(name: "integration_test_topic #{Time.now.to_f}")
    end

    expect(topic.to_param).to eq("UKGOVUK_908")
    expect(topic.topic_uri).to eq("/api/account/UKGOVUK/topics/UKGOVUK_908.xml")
  end

  it "sends a bulletin" do
    # When re-recording this response you must use an existing Topic which must
    # have at least one subscriber. You can do this in the staging admin
    # interface https://stage-admin.govdelivery.com

    topic_id = "UKGOVUK_935"
    notification = nil

    VCR.use_cassette("notify_topics") do
      notification = client.notify_topics(
        [topic_id],
        "Integration test subject",
        "Integration test message body",
      )
    end

    expect(notification.total_subscribers).to eq("2")
  end
end
