require "faraday"

module GovDeliveryClient
  def self.create_client(config)
    ClientFactory.new(
      config.merge(
        http_client_factory: method(:http_client_factory),
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

  class ClientFactory
    def initialize(config)
      @http_client_factory = config.fetch(:http_client_factory)
      @protocol = config.fetch(:protocol)
      @hostname = config.fetch(:hostname)
      @account_code = config.fetch(:account_code)
      @username = config.fetch(:username)
      @password = config.fetch(:password)
    end

    def call
      Client.new(
        http_client: http_client,
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
    end

    def create_topic(attributes)
      http_client.post(
        "topics.xml",
        create_topic_xml(attributes),
        content_type: "application/xml",
      )
    end

  private
    attr_reader :http_client

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
  end
end
