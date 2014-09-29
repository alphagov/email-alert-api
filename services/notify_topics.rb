class NotifyTopics
  def initialize(gov_delivery_client:, topics_repository:, topic_searcher:, subject:, body:, tags:, context:)
    @gov_delivery_client = gov_delivery_client
    @topics_repository = topics_repository
    @topic_searcher = topic_searcher
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
    :topic_searcher,
    :subject,
    :body,
    :tags,
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

  def topics
    topic_searcher.call(
      publication_tags: tags,
      search_topics: all_the_topics_yes_all_of_them,
    )
  end

  def all_the_topics_yes_all_of_them
    topics_repository.all
  end
end
