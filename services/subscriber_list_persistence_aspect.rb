class SubscriberListPersistenceAspect
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
    persist_subscriber_list(stuff.fetch(:subscriber_list))
    context.created(stuff)
  end

private
  attr_reader(
    :repo,
    :service,
    :context,
  )

  def persist_subscriber_list(subscriber_list)
    repo.store(subscriber_list.gov_delivery_id, subscriber_list)
  end
end
