class NotifyTopics
  def initialize(gov_delivery_client:, subject:, body:, topics:, context:)
    @gov_delivery_client = gov_delivery_client
    @topics = topics
    @subject = subject
    @body = body
    @context = context
  end

  def call
    notify_topics

    context.accepted({})
  end

private
  attr_reader(
    :gov_delivery_client,
    :subject,
    :body,
    :topics,
    :context
  )

  def notify_topics
    topics.each do |topic|
      gov_delivery_client.notify_topic(
        topic.gov_delivery_id,
        subject,
        body,
      )
    end
  end
end
