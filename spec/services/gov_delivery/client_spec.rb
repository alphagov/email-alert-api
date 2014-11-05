require "spec_helper"

require "app/services/gov_delivery/request_builder"

RSpec.describe GovDelivery::Client do
  let(:config) {
    EmailAlertAPI.config.gov_delivery
  }

  subject(:client) {
    GovDelivery::Client.new(config)
  }

  describe "#create_topic" do
    before do
      @base_url = "http://#{config.fetch(:username)}:#{config.fetch(:password)}@#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}/topics.xml"
      @topic_name = "Test topic"
      @govdelivery_response = %{<?xml version="1.0" encoding="UTF-8"?>
        <topic>
          <to-param>UKGOVUK_1234</to-param>
          <topic-uri>/api/account/UKGOVUK/topics/UKGOVUK_1234.xml</topic-uri>
          <link rel="self" href="/api/account/UKGOVUK/topics/UKGOVUK_1234"/>
        </topic>
      }
    end

    it "POSTs the topic creation request XML to the topics endpoint" do
      stub_request(:post, @base_url).to_return(body: @govdelivery_response)

      client.create_topic(@topic_name)

      assert_requested(:post, @base_url) do |req|
        expect(req.body).to be_equivalent_to(%{
          <topic>
            <name>#{@topic_name}</name>
            <short-name>#{@topic_name}</short-name>
            <visibility>Unlisted</visibility>
            <pagewatch-enabled type="boolean">false</pagewatch-enabled>
            <rss-feed-url nil="true"/>
            <rss-feed-title nil="true"/>
            <rss-feed-description nil="true"/>
          </topic>
        })
      end
    end

    it "returns an object that encapsulates the parsed response" do
      stub_request(:post, @base_url).to_return(body: @govdelivery_response)

      response = client.create_topic(@topic_name)

      expect(response).to be_equivalent_to(Struct.new(
        :to_param, :topic_uri, :link
      ).new(
        "UKGOVUK_1234", "/api/account/UKGOVUK/topics/UKGOVUK_1234.xml", ""
      ))
    end
  end

  describe "#send_bulletin" do
    before do
      @base_url = "http://#{config.fetch(:username)}:#{config.fetch(:password)}@#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}/bulletins/send_now.xml"
      @topic_name = "Test topic"
      @govdelivery_response = %{<?xml version="1.0" encoding="UTF-8"?>
        <bulletin>
          <to-param>7895129</to-param>
          <bulletin-uri>/api/account/UKGOVUK/bulletins/7895129.xml</bulletin-uri>
          <link rel="self" href="/api/account/UKGOVUK/bulletins/7895129"/>
          <total-subscribers>2</total-subscribers>
          <link rel="details" href="/api/account/UKGOVUK/bulletin_details/7895129"/>
        </bulletin>
      }
    end

    let(:topic_ids) {
      [
        "UKGOVUK_123",
        "UKGOVUK_124",
        "UKGOVUK_125",
      ]
    }

    let(:subject) { "a subject line" }
    let(:body) { "a body" }

    it "POSTs the bulletin XML to the send_now endpoint" do
      stub_request(:post, @base_url).to_return(body: @govdelivery_response)

      client.send_bulletin(topic_ids, subject, body)

      assert_requested(:post, @base_url) do |req|
        expect(req.body).to be_equivalent_to(
          %{
            <bulletin>
              <subject>a subject line</subject>
              <body><![CDATA[a body]]></body>
              <topics type="array">
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
      end
    end

    it "returns an object that encapsulates the parsed response" do
      stub_request(:post, @base_url).to_return(body: @govdelivery_response)

      response = client.send_bulletin(topic_ids, subject, body)

      expect(response).to be_equivalent_to(Struct.new(
        :to_param, :bulletin_uri, :link, :total_subscribers, :link
      ).new(
        "7895129", "/api/account/UKGOVUK/bulletins/7895129.xml", "", "2", ""
      ))
    end
  end
end
