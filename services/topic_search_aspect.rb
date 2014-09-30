class TopicSearchAspect
  def initialize(service:, repo:, topic_searcher:, tags:, context:)
    @service = service
    @repo = repo
    @topic_searcher = topic_searcher
    @tags = tags
    @context = context
  end

  def call
    service.call(topics, context)
  end

private

  def topics
    topic_searcher.call(
      publication_tags: tags,
      search_topics: all_topics,
    )
  end

  def all_topics
    repo.all
  end

  attr_reader(
    :service,
    :repo,
    :topic_searcher,
    :tags,
    :context,
  )
end
