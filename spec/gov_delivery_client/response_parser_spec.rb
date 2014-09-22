require "spec_helper"
require "gov_delivery_client"

RSpec.describe GovDeliveryClient::ResponseParser do
  subject(:response_parser) {
    GovDeliveryClient::ResponseParser.new(
      xml_parser: Nokogiri::XML.method(:parse)
    )
  }

  let(:gov_delivery_topic_id) { "UKGOVUK_908" }
  let(:gov_delivery_topic_uri) { "/api/account/UKGOVUK/topics/UKGOVUK_908.xml" }

  let(:response_body) {
    %{
      <?xml version="1.0" encoding="UTF-8"?>
      <topic>
        <to-param>#{gov_delivery_topic_id}</to-param>
        <topic-uri>#{gov_delivery_topic_uri}</topic-uri>
        <link rel="self" href="/api/account/UKGOVUK/topics/#{gov_delivery_topic_id}"/>
      </topic>
    }
  }

  it "extracts the id from the XML response" do
    expect(response_parser.call(response_body).id).to eq(gov_delivery_topic_id)
  end
end
