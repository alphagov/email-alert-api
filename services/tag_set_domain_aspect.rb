class TagSetDomainAspect
  def initialize(factory:, service:, context:, tags:)
    @factory = factory
    @service = service
    @context = context
    @tags = tags
  end

  def call
    service.call(context, tags: tag_set)
  end

  private

  attr_reader(
    :factory,
    :service,
    :context,
    :tags,
  )

  def tag_set
    factory.call(tags)
  end
end
