require "spec_helper"

require "equivalent-xml"
require "gov_delivery_client"

RSpec.describe GovDeliveryClient::Client do
  subject(:client) {
    GovDeliveryClient::Client.new(
      http_client: http_client,
      response_parser: response_parser,
    )
  }

  let(:response_parser) {
    double(
      :response_parser,
      call: nil,
    )
  }

  let(:http_client) {
    double(
      :http_client,
      get: nil,
      post: nil,
    )
  }

  let(:response) { double(:response, body: response_body) }

  describe "#create_topic" do
    let(:topic_name) { "A topical name" }
    let(:response_body) { double(:response_body) }
    let(:parsed_response) { double(:parsed_response) }

    before do
      allow(http_client).to receive(:post).and_return(response)
      allow(response_parser).to receive(:call).and_return(parsed_response)
    end

    it "POSTs the topic creation request XML to the topics endpoint" do
      client.create_topic(
        name: topic_name,
      )

      expect(http_client).to have_received(:post) do |url, xml, headers|
        expect(url).to eq("topics.xml")

        expect(xml).to be_equivalent_to(
          %{
            <topic>
              <name>#{topic_name}</name>
              <short-name>#{topic_name}</short-name>
              <visibility>Unlisted</visibility>
              <pagewatch-enabled type="boolean">false</pagewatch-enabled>
              <rss-feed-url nil="true"></rss-feed-url>
              <rss-feed-title nil="true"></rss-feed-title>
              <rss-feed-description nil="true"></rss-feed-description>
            </topic>
          }
        )

        expect(headers).to match(hash_including(content_type: "application/xml"))
      end
    end

    it "parses the response body" do
      client.create_topic(name: topic_name)

      expect(response_parser).to have_received(:call).with(response_body)
    end

    it "returns an object that encapsulates the parsed response" do
      expect(client.create_topic(name: topic_name)).to eq(parsed_response)
    end
  end

  describe "#send_bulletin" do
    let(:response_body) { double(:response_body) }
    let(:parsed_response) { double(:parsed_response) }

    before do
      allow(http_client).to receive(:post).and_return(response)
      allow(response_parser).to receive(:call).and_return(parsed_response)
    end

    let(:topic_ids) {
      [
        "UKGOVUK_123",
        "UKGOVUK_124",
        "UKGOVUK_125",
      ]
    }

    let(:subject) { "a subject line" }
    let(:body) { "a beautiful body" }

    it "POSTs the topic creation request XML to the topics endpoint" do
      client.send_bulletin(
        topic_ids,
        subject,
        body,
      )

      expect(http_client).to have_received(:post) do |url, xml, headers|
        expect(url).to eq("bulletins/send_now.xml")

        expect(xml).to be_equivalent_to(
          %{
            <bulletin>
              <subject>a subject line</subject>
              <body><![CDATA[a beautiful body]]></body>
              <topics type='array'>
                <topic>
                  <code>UKGOVUK_123</code>
                </topic>
                <topic>
                  <code>UKGOVUK_124</code>
                </topic>
                <topic>
                  <code>UKGOVUK_125</code>
                </topic>
              </topics>
            </bulletin>
          }
        )

        expect(headers).to match(hash_including(content_type: "application/xml"))
      end
    end

    it "returns an object that encapsulates the parsed response" do
      expect(
        client.send_bulletin(
          topic_ids,
          subject,
          body,
        )
      ).to eq(parsed_response)
    end
  end
end
