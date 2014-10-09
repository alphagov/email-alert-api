class SubscriberListSearchAspect
  def initialize(service:, repo:, responder:, subscriber_list_searcher:, tags:)
    @service = service
    @repo = repo
    @subscriber_list_searcher = subscriber_list_searcher
    @tags = tags
    @responder = responder
  end

  def call
    service.call(responder, subscriber_lists: subscriber_lists)
  end

private

  def subscriber_lists
    subscriber_list_searcher.call(
      publication_tags: tags,
      search_subscriber_lists: all_subscriber_lists,
    )
  end

  def all_subscriber_lists
    repo.all
  end

  attr_reader(
    :service,
    :repo,
    :subscriber_list_searcher,
    :tags,
    :responder,
  )
end
