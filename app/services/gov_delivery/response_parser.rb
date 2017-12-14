module GovDelivery
  class ResponseParser
    def initialize(response_body)
      @response_body = response_body
    end

    def parse
      Struct.new(*keys).new(*values)
    end

    def xml?
      xml_tree.root.present?
    end

  private

    attr_reader :response_body

    def keys
      first_level_element_nodes
        .map(&:node_name)
        .map { |k| k.tr("-", "_") }
        .map(&:to_sym)
    end

    def values
      # This returns all values as strings rather than observing the `type`s
      # in the XML, so beware of comparisons like 0 == '0'
      first_level_element_nodes.map(&:text)
    end

    def first_level_element_nodes
      reject_duplicate_nodes(
        reject_links(
          xml_tree.root.element_children
        )
      )
    end

    def reject_links(nodes)
      # Remove <link> tags since there are many of them, we don't use them,
      # and they break the "no duplicates in a Struct" rule
      nodes.reject do |node|
        node.name == "link"
      end
    end

    def reject_duplicate_nodes(nodes)
      nodes.uniq(&:name)
    end

    def xml_tree
      @xml_tree ||= xml_parser.call(response_body)
    end

    def xml_parser
      @xml_parser ||= Nokogiri::XML.method(:parse)
    end
  end
end
