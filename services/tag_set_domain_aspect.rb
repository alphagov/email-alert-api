class TagSetDomainAspect
  def initialize(factory:, service:, responder:, tags:)
    @factory = factory
    @service = service
    @responder = responder
    @tags = tags
  end

  def call
    service.call(responder, tags: tag_set)
  end

  private

  attr_reader(
    :factory,
    :service,
    :responder,
    :tags,
  )

  def tag_set
    factory.call(tags)
  end
end
