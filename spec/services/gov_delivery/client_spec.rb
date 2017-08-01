require "rails_helper" # These tests use #strip_heredoc which is in ActiveSupport
require "base64"

require "app/services/gov_delivery/client"
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
      @base_url = "http://#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}/topics.xml"
      @http_auth = Base64.strict_encode64("#{config.fetch(:username)}:#{config.fetch(:password)}")
      @topic_name = "Test topic"
      @govdelivery_response = %{<?xml version="1.0" encoding="UTF-8"?>
        <topic>
          <to-param>UKGOVUK_1234</to-param>
          <topic-uri>/api/account/UKGOVUK/topics/UKGOVUK_1234.xml</topic-uri>
          <link rel="self" href="/api/account/UKGOVUK/topics/UKGOVUK_1234"/>
        </topic>
      }

      stub_request(:post, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: @govdelivery_response)
    end

    it "POSTs the topic creation request XML to the topics endpoint" do
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
      response = client.create_topic(@topic_name)

      expect(response).to be_equivalent_to(Struct.new(
        :to_param, :topic_uri
      ).new(
        "UKGOVUK_1234", "/api/account/UKGOVUK/topics/UKGOVUK_1234.xml"
      ))
    end

    context "when the topic already exists" do
      before do
        stub_request(:post, @base_url).
          with(headers: { "Authorization" => "Basic #{@http_auth}" }).
          to_return(body: %{<?xml version=\"1.0\" encoding=\"UTF-8\"?>
          <errors>
            <code>GD-14004</code>
            <error>Name must be unique for an account</error>
          </errors>
        }, status: 422)
      end

      it "raises a TopicAlreadyExistsError" do
        expect { client.create_topic(@topic_name) }.to raise_error(GovDelivery::Client::TopicAlreadyExistsError)
      end
    end

    context "when a topic ID is provided" do
      let(:topic_id) { "UKGOVUK_PROVIDED_CODE" }

      it "sends the ID as the 'code'" do
        client.create_topic(@topic_name, topic_id)

        assert_requested(:post, @base_url) do |req|
          expect(req.body).to be_equivalent_to(%{
            <topic>
              <code>#{topic_id}</code>
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
    end
  end

  describe '#fetch_topic' do
    let(:topic_code) { "UKGOV_1234" }
    let(:base_url) { @base_url = "http://#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}/topics/#{topic_code}.xml" }
    let(:http_auth) { @http_auth = Base64.strict_encode64("#{config.fetch(:username)}:#{config.fetch(:password)}") }
    before do
      stub_request(:get, base_url).
        with(headers: { "Authorization" => "Basic #{http_auth}" }).
        to_return(body: govdelivery_response)
    end

    context 'when topic exists' do
      let(:govdelivery_response) do
        <<-XML.strip_heredoc
          <?xml version="1.0" encoding="UTF-8"?>
          <topic>
            <name>Topic name</name>
            <short-name>Topic short name</short-name>
            <code>#{topic_code}</code>
            <pagewatch-enabled type="boolean">false</pagewatch-enabled>
            <lock-version type="integer">0</lock-version>
            <description nil="true"/>
            <watch-tagged-content type="boolean">false</watch-tagged-content>
            <pagewatch-autosend type="boolean">false</pagewatch-autosend>
            <default-pagewatch-results type="integer" nil="true"/>
            <pagewatch-suspended type="boolean">true</pagewatch-suspended>
            <rss-feed-title nil="true"/>
            <rss-feed-url>https://www.gov.uk/government</rss-feed-url>
            <rss-feed-description nil="true"/>
            <subscribers-count type="integer">0</subscribers-count>
            <wireless-enabled type="boolean">false</wireless-enabled>
            <pagewatch-type type="integer" nil="true"/>
            <pages type="array"/>
            <visibility>Unlisted</visibility>
          </topic>
        XML
      end

      it 'returns a hash representation of the topic' do
        expect(client.fetch_topic(topic_code)).to have_attributes(
          'name' => 'Topic name',
          'short_name' => 'Topic short name',
          'code' => 'UKGOV_1234',
          'pagewatch_enabled' => 'false',
          'lock_version' => '0',
          'description' => '',
          'watch_tagged_content' => 'false',
          'pagewatch_autosend' => 'false',
          'default_pagewatch_results' => '',
          'pagewatch_suspended' => 'true',
          'rss_feed_title' => '',
          'rss_feed_url' => 'https://www.gov.uk/government',
          'rss_feed_description' => '',
          'subscribers_count' => '0',
          'wireless_enabled' => 'false',
          'pagewatch_type' => '',
          'pages' => '',
          'visibility' => 'Unlisted'
        )
      end
    end

    context 'when topic does not exist' do
      let(:govdelivery_response) do
        <<-XML.strip_heredoc
          <?xml version="1.0" encoding="UTF-8"?>
          <errors>
            <code>GD-14002</code>
            <error>Topic not found</error>
          </errors>
        XML
      end

      it 'raises a TopicNotFound error' do
        expect { client.fetch_topic(topic_code) }.to raise_error(GovDelivery::Client::TopicNotFound)
      end
    end
  end

  describe "#read_topic_by_name" do
    before do
      @topic_name = "Test topic"
      @base_url = "http://#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}/topics.xml"
      @http_auth = Base64.strict_encode64("#{config.fetch(:username)}:#{config.fetch(:password)}")

      @govdelivery_response = %{
        <?xml version="1.0" encoding="UTF-8"?>
        <topics type="array">
          <topic>
            <code>UKGOVUK_1234</code>
            <description nil="true">topic description here</description>
            <name>#{@topic_name}</name>
            <short-name>TOPIC_SHORT_NAME</short-name>
            <wireless-enabled type="boolean">false</wireless-enabled>
            <visibility>Listed</visibility>
            <link rel="self" href="/api/account/UKGOVUK/topics/UKGOVUK_1234"/>
          </topic>
          <topic>
            <code>UKGOVUK_4321</code>
            <description nil="true">topic description here</description>
            <name>#{@topic_name.reverse}</name>
            <short-name>EMAN_TROHS_CIPOT</short-name>
            <wireless-enabled type="boolean">false</wireless-enabled>
            <visibility>Listed</visibility>
            <link rel="self" href="/api/account/UKGOVUK/topics/UKGOVUK_4321"/>
          </topic>
        </topics>
      }
    end

    it "returns an object that represents the existing topic" do
      stub_request(:get, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: @govdelivery_response)

      response = client.read_topic_by_name(@topic_name)

      expect(response).to be_equivalent_to(Struct.new(
        :to_param, :topic_uri, :link
      ).new(
        "UKGOVUK_1234", "/api/account/UKGOVUK/topics/UKGOVUK_1234.xml", ""
      ))
    end
  end

  describe "#send_bulletin" do
    before do
      @base_url = "http://#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}/bulletins/send_now.xml"
      @http_auth = Base64.strict_encode64("#{config.fetch(:username)}:#{config.fetch(:password)}")
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
      stub_request(:post, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: @govdelivery_response)

      client.send_bulletin(topic_ids, subject, body)

      expected_xml = <<-XML.strip_heredoc
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
          <footer><![CDATA[#{GovDelivery::RequestBuilder.default_footer}]]></footer>
        </bulletin>
      XML
      assert_requested(:post, @base_url) do |req|
        expect(req.body).to be_equivalent_to(expected_xml)
      end
    end

    it "fails silently on zero subscriber error from govdelivery" do
      @govdelivery_response = %{
        <?xml version="1.0" encoding="UTF-8"?>
        <errors>
          <code>GD-12004</code>
          <error>To send a bulletin you must select at least one topic or category that has subscribers</error>
        </errors>
      }
      stub_request(:post, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: @govdelivery_response)

      expect { client.send_bulletin(topic_ids, subject, body) }.not_to raise_error
    end

    it "raises a helpful error for empty responses from govdelivery" do
      stub_request(:post, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: "")

      expect { client.send_bulletin(topic_ids, subject, body) }.to raise_error(GovDelivery::Client::UnexpectedResponseBodyError)
    end

    it "raises error on any other error from govdelivery" do
      @govdelivery_response = %{
        <?xml version="1.0" encoding="UTF-8"?>
        <errors>
          <code>GD-12004</code>
          <error>Invalid bulletin</error>
        </errors>
      }
      stub_request(:post, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: @govdelivery_response)

      expect do
        client.send_bulletin(topic_ids, subject, body)
      end.to raise_error(GovDelivery::Client::UnknownError)
    end

    it "POSTs the bulletin with extra parameters (EXCEPT FOOTER) if present to the send_now endpoint" do
      stub_request(:post, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: @govdelivery_response)

      client.send_bulletin(topic_ids, subject, body, {
        from_address_id: 12345,
        urgent: true,
        header: "<h1>Foo</h1>",
        footer: "<p>bar</p>"
      })

      expected_xml = <<-XML.strip_heredoc
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
          <from_address_id>12345</from_address_id>
          <urgent>true</urgent>
          <header><![CDATA[<h1>Foo</h1>]]></header>
          <footer><![CDATA[#{GovDelivery::RequestBuilder.default_footer}]]></footer>
        </bulletin>
      XML
      assert_requested(:post, @base_url) do |req|
        expect(req.body).to be_equivalent_to(expected_xml)
      end
    end

    it "returns an object that encapsulates the parsed response" do
      stub_request(:post, @base_url).
        with(headers: { "Authorization" => "Basic #{@http_auth}" }).
        to_return(body: @govdelivery_response)

      response = client.send_bulletin(topic_ids, subject, body)

      expect(response).to be_equivalent_to(Struct.new(
        :to_param, :bulletin_uri, :total_subscribers
      ).new(
        "7895129", "/api/account/UKGOVUK/bulletins/7895129.xml", "2"
      ))
    end
  end

  describe "fetch_bulletins" do
    let(:bulletins_response) do
      <<-XML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8"?>
      <bulletins>
        <bulletin>
          <subject>Australia travel advice</subject>
          <bulletin-uri>/api/account/UKGOVUK/bulletins/12791099.xml</bulletin-uri>
          <to-param>1928</to-param>
        </bulletin>
        <bulletin>
          <subject>Belgium travel advice</subject>
          <bulletin-uri>/api/account/UKGOVUK/bulletins/12791019.xml</bulletin-uri>
          <to-param>1019</to-param>
        </bulletin>
      </bulletins>
      XML
    end

    let(:bulletins_hash) do
      {
        "bulletins" => {
          "bulletin" => [
            {
              "subject" => "Australia travel advice",
              "bulletin_uri" => "/api/account/UKGOVUK/bulletins/12791099.xml",
              "to_param" => "1928"
            },
            {
              "subject" => "Belgium travel advice",
              "bulletin_uri" => "/api/account/UKGOVUK/bulletins/12791019.xml",
              "to_param" => "1019"
            },
          ]
        }
      }
    end

    context "with no start_at param" do
      before do
        stub_request(:get, %r{^.*?/api/account/UKGOVUK/bulletins/sent\.xml$})
          .to_return(status: 200, body: bulletins_response)
      end

      it "returns the response received from govdelivery" do
        expect(client.fetch_bulletins).to eq(bulletins_hash)
      end
    end

    context "with a start_at param" do
      let(:uri_regex) { %r{^.*?/api/account/UKGOVUK/bulletins/sent\.xml\?start_at=1928$} }

      before do
        stub_request(:get, uri_regex)
          .to_return(status: 200, body: bulletins_response)
      end

      it "returns the response received from govdelivery" do
        expect(client.fetch_bulletins("1928")).to eq(bulletins_hash)
      end

      it "includes the start_at param in the govdelivery request" do
        client.fetch_bulletins("1928")
        expect(WebMock).to have_requested(:get, uri_regex)
      end
    end

    context "GovDelivery responds with an error" do
      it "returns the error response without raising" do
        govdelivery_response = %{
          <?xml version="1.0" encoding="UTF-8"?>
          <errors>
            <code>GD-12015</code>
            <error>Resource not available.</error>
          </errors>
        }
        stub_request(:get, %r{^.*?/api/account/UKGOVUK/bulletins/sent\.xml$})
          .to_return(status: 403, body: govdelivery_response)

        expect(client.fetch_bulletins).to eq(
          "errors" => {"code"=>"GD-12015", "error"=>"Resource not available."}
        )
      end
    end
  end

  describe "fetch_bulletin" do
    let(:bulletin_response) do
      <<-XML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8"?>
      <bulletin>
        <subject>Australia travel advice</subject>
        <body>Some body text</body>
      </bulletin>
      XML
    end

    before do
      stub_request(:get, %r{^.*?/api/account/UKGOVUK/bulletins/12345.xml$})
        .to_return(status: 200, body: bulletin_response)
    end

    it "returns the response received from govdelivery" do
      expect(client.fetch_bulletin("12345")).to eq({
        "bulletin" => {
          "subject" => "Australia travel advice",
          "body" => "Some body text",
        }
      })
    end

    context "GovDelivery responds with an error" do
      it "returns the error response without raising" do
        govdelivery_response = %{
          <?xml version="1.0" encoding="UTF-8"?>
          <errors>
            <code>GD-12002</code>
            <error>Bulletin not found.</error>
          </errors>
        }
        stub_request(:get, %r{^.*?/api/account/UKGOVUK/bulletins/sent\.xml$})
          .to_return(status: 402, body: govdelivery_response)

        expect(client.fetch_bulletins).to eq(
          "errors" => {"code"=>"GD-12002", "error"=>"Bulletin not found."}
        )
      end
    end
  end

  describe "fetch_topics" do
    let(:topics_response) do
      <<-XML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8"?>
      <topics type="array">
        <topic>
          <code>TOPIC_123</code>
          <description nil="true">Topic description 1</description>
          <name>Topic name 1</name>
          <short-name>Topic short name 1</short-name>
          <wireless-enabled type="boolean">false</wireless-enabled>
          <visibility>Listed</visibility>
          <link rel="self" href="/api/account/ACCOUNT_CODE/topics/TOPIC_123"/>
        </topic>
        <topic>
          <code>TOPIC_456</code>
          <description nil="true">Topic description 2</description>
          <name>Topic name 2</name>
          <short-name>Topic short name 2</short-name>
          <wireless-enabled type="boolean">false</wireless-enabled>
          <visibility>Listed</visibility>
          <link rel="self" href="/api/account/ACCOUNT_CODE/topics/TOPIC_456"/>
        </topic>
      </topics>
      XML
    end

    let(:topics_hash) do
      {
        "topics" => [
          {
            "code" => "TOPIC_123",
            "description" => "Topic description 1",
            "name" => "Topic name 1",
            "short_name" => "Topic short name 1",
            "wireless_enabled" => false,
            "visibility" => "Listed",
            "link" => {
              "rel" => "self",
              "href"=>"/api/account/ACCOUNT_CODE/topics/TOPIC_123"
            },
          },
          {
            "code" => "TOPIC_456",
            "description" => "Topic description 2",
            "name" => "Topic name 2",
            "short_name" => "Topic short name 2",
            "wireless_enabled" => false,
            "visibility" => "Listed",
            "link" => {
              "rel" => "self",
              "href"=>"/api/account/ACCOUNT_CODE/topics/TOPIC_456"
            },
          },
        ]
      }
    end

    before do
      stub_request(:get, %r{^.*?/api/account/UKGOVUK/topics\.xml$})
        .to_return(status: 200, body: topics_response)
    end

    it "returns the response received from govdelivery" do
      expect(client.fetch_topics).to eq(topics_hash)
    end
  end

  describe "delete_topic(topic_id)" do
    let(:topic_id) { "UKGOVUK_123" }

    before do
      stub_request(:delete, %r{^.*?/api/account/UKGOVUK/topics/.*$})
    end

    it "sends a DELETE to the appropriate topic URL" do
      client.delete_topic(topic_id)
      expect(WebMock).to have_requested(:delete, %r{^.*?/api/account/UKGOVUK/topics/#{topic_id}\.xml$})
    end
  end
end
