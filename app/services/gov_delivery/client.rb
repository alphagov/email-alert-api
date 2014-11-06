module GovDelivery
  class Client
    class UnknownError < StandardError; end
    class TopicAlreadyExistsError < UnknownError; end

    def initialize(options = {})
      @options = options
    end

    def create_topic(name)
      # GovDelivery documentation for this endpoint:
      # http://knowledge.govdelivery.com/display/API/Create+Topic
      parse_topic_response(
        post_xml(
          "topics.xml",
          RequestBuilder.create_topic_xml(name),
        )
      )
    end

    def read_topic_by_name(name)
      # GovDelivery documentation for this endpoint:
      # https://knowledge.govdelivery.com/display/API/List+Topic
      parse_topic_list_response(
        http_client.get("topics.xml"),
        name,
      )
    end

    def send_bulletin(topic_ids, subject, body)
      # GovDelivery documentation for this endpoint:
      # http://knowledge.govdelivery.com/display/API/Create+and+Send+Bulletin
      parse_topic_response(
        post_xml(
          "bulletins/send_now.xml",
          RequestBuilder.send_bulletin_xml(topic_ids, subject, body),
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

    def parse_topic_response(response)
      ResponseParser.new(response.body).parse.tap do |parsed_response|
        raise_correct_error(parsed_response) if parsed_response.respond_to? :error
      end
    end

    def parse_topic_list_response(response, name)
      TopicListResponseParser.new(
        response.body,
        name,
      ).parse
    end

    def raise_correct_error(parsed_response)
      error_class = case parsed_response.code
                    when "GD-14004" then TopicAlreadyExistsError
                    else UnknownError
                    end

      raise error_class.new, "#{parsed_response.code}: #{parsed_response.error}"
    end
  end
end
