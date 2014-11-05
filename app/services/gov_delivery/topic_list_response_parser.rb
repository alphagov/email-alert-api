module GovDelivery
  class TopicListResponseParser
    def initialize(response_body, desired_name)
      @xml_parser = Nokogiri::XML.method(:parse)
      @response_body = response_body
      @desired_name = desired_name
    end

    def parse
      return nil unless topic.present?
      Struct.new(*keys).new(*values)
    end

  private
    # Returning a struct with these keys matches the API of the ResponseParser
    def keys
      [:to_param, :topic_uri, :link]
    end

    def values
      topic_link = topic.xpath("link").attribute("href").text

      [
        topic.xpath("code").text,
        "#{topic_link}.xml",
        "",
      ]
    end

    def topic
      @topic ||= xml_tree.xpath("//topics/topic[name[contains(., \"#{desired_name}\")]]")
    end

    attr_reader(
      :xml_parser,
      :response_body,
      :desired_name,
    )

    def xml_tree
      @xml_tree ||= xml_parser.call(response_body)
    end
  end
end
