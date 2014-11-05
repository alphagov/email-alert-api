module GovDelivery
  module RequestBuilder
    def self.create_topic_xml(name)
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

    def self.send_bulletin_xml(topic_ids, subject, body)
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
  end
end
