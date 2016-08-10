module GovDelivery
  class Client
    class UnknownError < StandardError; end
    class TopicAlreadyExistsError < UnknownError; end
    class ZeroSubscriberError < UnknownError; end
    class UnexpectedResponseBodyError < UnknownError; end

    def initialize(options = {})
      @options = options
    end

    def create_topic(name)
      # GovDelivery documentation for this endpoint:
      # http://developer.govdelivery.com/api_docs/comm_cloud_v1/#API/Comm Cloud V1/API_CommCloudV1_Topics_CreateTopic.htm
      parse_topic_response(
        EmailAlertAPI.statsd.time('topics.create') do
          post_xml(
            "topics.xml",
            RequestBuilder.create_topic_xml(name),
          )
        end
      )
    end

    def delete_topic(topic_id)
      # GovDelivery documentation for this endpoint:
      # http://developer.govdelivery.com/api/comm_cloud_v1/Default.htm#API/Comm Cloud V1/API_CommCloudV1_Topics_DeleteTopic.htm
      http_client.delete("topics/#{topic_id}.xml")
    end

    def ping
      http_client.get("categories.xml")
    end

    def read_topic_by_name(name)
      # GovDelivery documentation for this endpoint:
      # http://developer.govdelivery.com/api_docs/comm_cloud_v1/#API/Comm Cloud V1/API_CommCloudV1_Topics_ListTopics.htm
      # Warning: This currently takes unnacceptably long (40 seconds on staging), so is not used
      # See https://github.com/alphagov/email-alert-api/pull/61
      parse_topic_list_response(
        EmailAlertAPI.statsd.time('topics.list') { http_client.get("topics.xml") },
        name,
      )
    end

    def send_bulletin(topic_ids, subject, body, options = {})
      # GovDelivery documentation for this endpoint:
      # http://developer.govdelivery.com/api_docs/comm_cloud_v1/#API/Comm Cloud V1/API_CommCloudV1_Bulletins_CreateandSendBulletin.htm
      parse_topic_response(
        EmailAlertAPI.statsd.time('bulletin.send') do
          post_xml(
            "bulletins/send_now.xml",
            RequestBuilder.send_bulletin_xml(topic_ids, subject, body, options),
          )
        end
      )
    rescue ZeroSubscriberError
    end

    def fetch_bulletins(start_at=nil)
      # GovDelivery documentation for this endpoint:
      # http://developer.govdelivery.com/api/comm_cloud_v1/Default.htm#API/Comm Cloud V1/API_CommCloudV1_Bulletins_ListSentBulletins.htm
      endpoint = "bulletins/sent.xml"
      endpoint += "?start_at=#{start_at}" if start_at
      response = http_client.get(endpoint)
      Hash.from_xml(response.body)
    end

    def fetch_bulletin(id)
      # GovDelivery documentation for this endpoint:
      # http://developer.govdelivery.com/api/comm_cloud_v1/Default.htm#API/Comm Cloud V1/API_CommCloudV1_Bulletins_ReadBulletin.htm
      response = http_client.get("bulletins/#{id}.xml")
      Hash.from_xml(response.body)
    end

    def fetch_topics
      # GovDelivery documentation for this endpoint:
      # http://developer.govdelivery.com/api/comm_cloud_v1/Default.htm#API/Comm Cloud V1/API_CommCloudV1_Topics_ListTopics.htm
      response = http_client.get("topics.xml")
      Hash.from_xml(response.body)
    end

  private
    attr_reader :options

    def logger
      unless @logger
        @logger = Logger.new(File.join(Rails.root, "log/govdelivery.log"))
        @logger.formatter = proc do |severity, datetime, progname, msg|
          {
            "@fields.application" => "email-alert-api",
            "@timestamp" => datetime.iso8601,
            "@tags" => "govdelivery",
            "@message" => msg
          }.to_json + "\n"
        end
      end
      @logger
    end

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
      logger.info("XML sent to GovDelivery: #{body}")
      http_client.post(
        path,
        body,
        content_type: "application/xml",
      )
    end

    def parse_topic_response(response)
      EmailAlertAPI.statsd.increment("responses.#{response.status}")

      response_parser = ResponseParser.new(response.body)
      if response_parser.xml?
        response_parser.parse.tap do |parsed_response|
          raise_correct_error(parsed_response) if parsed_response.respond_to? :error
        end
      else
        raise UnexpectedResponseBodyError.new("Unexpected response from govdelivery: HTTP status code: #{response.status} body: #{response.body}")
      end
    end

    def parse_topic_list_response(response, name)
      TopicListResponseParser.new(
        response.body,
        name,
      ).parse
    end

    def raise_correct_error(parsed_response)
      if parsed_response.code == "GD-14004"
        error_class = TopicAlreadyExistsError
      elsif parsed_response.code == "GD-12004" && parsed_response.error == "To send a bulletin you must select at least one topic or category that has subscribers"
        error_class = ZeroSubscriberError
      else
        error_class = UnknownError
      end

      raise error_class.new, "#{parsed_response.code}: #{parsed_response.error}"
    end
  end
end
