module GovDelivery
  class ResponseParser
    def initialize(response_body)
      @xml_parser = Nokogiri::XML.method(:parse)
      @response_body = response_body
    end

    def parse
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
end
