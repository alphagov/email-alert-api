require "spec_helper"
require "gov_delivery_client"

RSpec.describe GovDeliveryClient::ResponseParser do
  subject(:response_parser) {
    GovDeliveryClient::ResponseParser.new(
      xml_parser: Nokogiri::XML.method(:parse),
      response_body: response_body,
      subscription_link_template: subscription_link_template,
    )
  }

  let(:gov_delivery_topic_id) { "UKGOVUK_908" }
  let(:gov_delivery_topic_uri) { "/api/account/UKGOVUK/topics/UKGOVUK_908" }
  let(:base_url) { "https://stage-public.govdelivery.com/accounts/UKGOVUK" }
  let(:subscription_link_template) { "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=%{topic_id}" }

  let(:response_body) {
    %{
      <?xml version="1.0" encoding="UTF-8"?>
      <topic>
        <to-param>#{gov_delivery_topic_id}</to-param>
        <topic-uri>#{gov_delivery_topic_uri}.xml</topic-uri>
        <link rel="self" href="#{gov_delivery_topic_uri}"/>
      </topic>
    }
  }

  it "extracts the id from the XML response" do
    parsed_response = response_parser.call

    expect(parsed_response.id).to eq(gov_delivery_topic_id)
  end

  it "extracts the topic subscription link" do
    parsed_response = response_parser.call

    expect(parsed_response.link).to eq(
      "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_908"
    )
  end
end
