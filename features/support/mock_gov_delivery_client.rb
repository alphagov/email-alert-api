require "ostruct"

class MockGovDeliveryClient
  def initialize
    reset!
    @id_start = 1234
    @insert_count = 0
  end

  def created_topics
    @topics
  end

  def notifications
    @notifications ||= []
  end

  def reset!
    @topics = {}
    @notifications = []
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

  def notify_topic(topic_id, subject, message)
    @notifications ||= []
    @notifications << OpenStruct.new(
      topic_id: topic_id,
      subject: subject,
      body: message,
    )
    nil
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
end

