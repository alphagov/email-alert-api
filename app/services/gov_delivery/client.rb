module GovDelivery
  class Client
    def initialize(options = {})
      @options = options
    end

    def create_topic(name)
      parse_topic_response(
        post_xml(
          "topics.xml",
          create_topic_xml(name),
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

    def post_xml(path, body)
      http_client.post(
        path,
        body,
        content_type: "application/xml",
      )
    end

    def create_topic_xml(name)
      Nokogiri::XML::Builder.new { |xml|
        xml.topic {
          xml.name name
          xml.send(:'short-name', name)
          xml.visibility 'Unlisted'
          xml.send(:'pagewatch-enabled', "false", type: :boolean)
          xml.send(:'rss-feed-url', nil: :true)
          xml.send(:'rss-feed-title', nil: :true)
          xml.send(:'rss-feed-description', nil: :true)
        }
      }.to_xml
    end

    def send_bulletin_xml(topic_ids, subject, body)
      Nokogiri::XML::Builder.new { |xml|
        xml.bulletin {
          xml.subject subject
          xml.body {
            xml.cdata body
          }
          xml.topics(type: 'array') {
            topic_ids.each { |id|
              xml.topic {
                xml.code id
              }
            }
          }
        }
      }.to_xml
    end

    def parse_topic_response(response)
      ResponseParser.new(response.body).parse
    end
  end
end
