class SubscriberListPersistenceAspect
  def initialize(service:, repo:, responder:)
    @repo = repo
    @service = service
    @responder = responder
  end

  def call
    service.call(responder.on(:created, &method(:created_callback)))
  end

private
  attr_reader(
    :repo,
    :service,
    :responder,
  )

  def created_callback(response)
    persist_subscriber_list(response.fetch(:subscriber_list))
  end

  def persist_subscriber_list(subscriber_list)
    repo.store(subscriber_list.gov_delivery_id, subscriber_list)
  end
end
