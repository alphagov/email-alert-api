require "ostruct"

class MockGovDeliveryClient
  def initialize
    initialize_ivars
  end

  def reset!
    initialize_ivars
  end

  def created_topics
    @topics
  end

  def notifications
    @notifications ||= []
  end

  def create_topic(attributes)
    topic_id = generate_topic_id

    @topics[topic_id] = attributes
    @insert_count += 1

    response = {
      to_param: topic_id,
      topic_uri: "/api/account/UKGOVUK/topics/#{topic_id}.xml",
    }

    Struct.new(*response.keys).new(*response.values)
  end

  def send_bulletin(topic_ids, subject, body)
    @notifications ||= []
    @notifications = @notifications.concat(
      topic_ids.map { |topic_id|
        OpenStruct.new(
          topic_id: topic_id,
          subject: subject,
          body: body,
        )
      }
    )

    OpenStruct.new(
      "bulletin" => {
          "to_param" => "7895129",
          "bulletin_uri" => "/api/account/UKGOVUK/bulletins/7895129.xml",
          "total_subscribers" => "2",
          "link" => "",
      }
    )
  end

  def generate_topic_id
    [
      "UKGOVUK",
      next_id,
    ].join("_")
  end

  def next_id
    @id_start + @insert_count
  end

  private

  def initialize_ivars
    @topics = {}
    @notifications = []
    @id_start = 1234
    @insert_count = 0
  end
end

