class NotifyTopics
  def initialize(gov_delivery_client:, topics_repository:, subject:, body:, tags:, context:)
    @gov_delivery_client = gov_delivery_client
    @topics_repository = topics_repository
    @subject = subject
    @body = body
    @tags = tags
    @context = context
  end

  def call
    notify_topics

    context.accepted({})
  end

private
  attr_reader(
    :topics_repository,
    :gov_delivery_client,
    :subject,
    :body,
    :tags,
    :context
  )

  def notify_topics
    topics.each do |topic|
      gov_delivery_client.notify_topic(
        topic.id,
        subject,
        body,
      )
    end
  end

  def topics
    topics_repository.find_by_publications_tags(tags)
  end
end
