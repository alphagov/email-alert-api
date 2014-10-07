class SubscriberListPersistenceAspect
  def initialize(service:, repo:, responder:)
    @repo = repo
    @service = service
    @responder = responder
  end

  def call
    service.call(responder_proxy)
  end

private
  attr_reader(
    :repo,
    :service,
    :responder,
  )

  def responder_proxy
    ResponderProxy.new(responder, method(:created_callback))
  end

  def created_callback(response)
    persist_subscriber_list(response.fetch(:subscriber_list))
  end

  def persist_subscriber_list(subscriber_list)
    repo.store(subscriber_list.gov_delivery_id, subscriber_list)
  end

  class ResponderProxy
    def initialize(responder, callback)
      @callback = callback
      @responder = responder
    end

    def created(response)
      callback.call(response)
      responder.created(response)
    end

    private

    attr_reader(
      :callback,
      :responder,
    )
  end
end
