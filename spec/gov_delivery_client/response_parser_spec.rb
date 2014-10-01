require "spec_helper"
require "gov_delivery_client"

RSpec.describe GovDeliveryClient::ResponseParser do
  subject(:response_parser) {
    GovDeliveryClient::ResponseParser.new(
      xml_parser: Nokogiri::XML.method(:parse),
      response_body: response_body,
    )
  }

  let(:gov_delivery_topic_id) { "UKGOVUK_908" }
  let(:gov_delivery_topic_uri) { "/api/account/UKGOVUK/topics/UKGOVUK_908.xml" }
  let(:gov_delivery_topic_link_href) { "/api/account/UKGOVUK/topics/UKGOVUK_908" }

  let(:response_body) {
    %{
      <?xml version="1.0" encoding="UTF-8"?>
      <topic>
        <to-param>#{gov_delivery_topic_id}</to-param>
        <topic-uri>#{gov_delivery_topic_uri}</topic-uri>
        <link rel="self" href="#{gov_delivery_topic_link_href}"/>
      </topic>
    }
  }

  it "extracts the id from the XML response" do
    parsed_response = response_parser.call

    expect(parsed_response.to_param).to eq(gov_delivery_topic_id)
  end

  it "extracts the topic subscription link" do
    parsed_response = response_parser.call

    expect(parsed_response.topic_uri).to eq(gov_delivery_topic_uri)
  end
end
