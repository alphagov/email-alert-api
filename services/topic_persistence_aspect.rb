class TopicPersistenceAspect
  def initialize(service:, repo:, context:)
    @repo = repo
    @service = service
    @context = context
  end

  def call
    service.call(self)
  end

  def params
    context.params
  end

  def created(stuff)
    persist_topic(stuff.fetch(:topic))
    context.created(stuff)
  end

private
  attr_reader(
    :repo,
    :service,
    :context,
  )

  def persist_topic(topic)
    repo.store(topic.gov_delivery_id, topic)
  end
end
