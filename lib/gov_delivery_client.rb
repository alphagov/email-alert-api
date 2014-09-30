require "faraday"
require "nokogiri"
require "ostruct"

module GovDeliveryClient
  def self.create_client(config)
    ClientFactory.new(
      config.merge(
        http_client_factory: method(:http_client_factory),
        response_parser: response_parser,
      )
    ).call
  end

  def self.http_client_factory(options, &block)
    Faraday.new(url: options.fetch(:url)) do |connection|
      block.call(connection) if block
      connection.use(
        Faraday::Request::BasicAuthentication,
        options.fetch(:username),
        options.fetch(:password),
      )
      connection.adapter(Faraday.default_adapter)
    end
  end

  def self.response_parser
    ->(response_body) {
      ResponseParser.new(
        xml_parser: Nokogiri::XML.method(:parse),
        response_body: response_body,
      ).call
    }
  end

  class ResponseParser
    def initialize(args)
      @xml_parser = args.fetch(:xml_parser)
      @response_body = args.fetch(:response_body)
    end

    def call
      Struct.new(*keys).new(*values)
    end

  private

    attr_reader(
      :xml_parser,
      :response_body,
    )

    def keys
      first_level_element_nodes
        .map(&:node_name)
        .map { |k| k.gsub("-", "_") }
        .map(&:to_sym)
    end

    def values
      first_level_element_nodes.map(&:text)
    end

    def first_level_element_nodes
      xml_tree.root.element_children
    end

    def xml_tree
      @xml_tree ||= xml_parser.call(response_body)
    end
  end

  class ClientFactory
    def initialize(config)
      @http_client_factory = config.fetch(:http_client_factory)
      @protocol = config.fetch(:protocol)
      @hostname = config.fetch(:hostname)
      @account_code = config.fetch(:account_code)
      @username = config.fetch(:username)
      @password = config.fetch(:password)
      @response_parser = config.fetch(:response_parser)
    end

    def call
      Client.new(
        http_client: http_client,
        response_parser: response_parser,
      )
    end

  private
    attr_reader(
      :http_client_factory,
      :protocol,
      :hostname,
      :account_code,
      :username,
      :password,
      :response_parser,
    )

    def http_client
      http_client_factory.call(
        url: base_url,
        username: username,
        password: password,
      )
    end

    def base_url
      "#{protocol}://#{hostname}/api/account/#{account_code}"
    end
  end

  class Client
    def initialize(dependencies = {})
      @http_client = dependencies.fetch(:http_client)
      @response_parser = dependencies.fetch(:response_parser)
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
    attr_reader :http_client, :response_parser

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
      response_parser.call(response.body)
    end
  end
end
