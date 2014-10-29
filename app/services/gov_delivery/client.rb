module GovDelivery
  class Client
    def initialize(options = {})
      @options = options
    end

    def create_topic(attributes)
      parse_topic_response(
        post_xml(
          "topics.xml",
          create_topic_xml(attributes),
        )
      )
    end

    def send_bulletin(topic_ids, subject, body)
      parse_topic_response(
        post_xml(
          "bulletins/send_now.xml",
          send_bulletin_xml(topic_ids, subject, body),
        )
      )
    end

  private

    attr_reader :options

    def base_url
      "#{options.fetch(:protocol)}://#{options.fetch(:hostname)}/api/account/#{options.fetch(:account_code)}"
    end

    def http_client
      @http_client ||= Faraday.new(url: base_url) do |connection|
        connection.use(
          Faraday::Request::BasicAuthentication,
          options.fetch(:username),
          options.fetch(:password),
        )
        connection.adapter(Faraday.default_adapter)
      end
    end

    def post_xml(path, params)
      http_client.post(
        path,
        params,
        content_type: "application/xml",
      )
    end

    def create_topic_xml(attributes)
      # TODO Write a spec to prevent content injection
      %{
        <topic>
          <name>%{name}</name>
          <short-name>%{name}</short-name>
          <visibility>Unlisted</visibility>
          <pagewatch-enabled type="boolean">false</pagewatch-enabled>
          <rss-feed-url nil="true"></rss-feed-url>
          <rss-feed-title nil="true"></rss-feed-title>
          <rss-feed-description nil="true"></rss-feed-description>
        </topic>
      } % attributes
    end

    def send_bulletin_xml(topic_ids, subject, body)
      topics = topic_ids
        .map { |id| topic_template % { id: id } }
        .join("\n")

      %{
        <bulletin>
          <subject>%{subject}</subject>
          <body><![CDATA[%{body}]]></body>
          <topics type='array'>
            %{topics}
          </topics>
        </bulletin>
       } % { subject: subject, body: body, topics: topics }
    end

    def topic_template
      %{
          <topic>
            <code>%{id}</code>
          </topic>
      }
    end

    def parse_topic_response(response)
      ResponseParser.new(response.body).parse
    end
  end
end
