class UniqueTagSetFilter
  def initialize(repo:, service:, responder:, tags:)
    @repo = repo
    @service = service
    @responder = responder
    @tags = tags
  end

  def call
    if repo.find_by_tags(tags.to_h).empty?
      service.call(responder, tags: tags)
    else
      responder.unprocessable(error: error_message)
    end
  end
private

  attr_reader(
    :repo,
    :service,
    :responder,
    :tags,
  )

  def error_message
    "A subscriber list with that tag set already exists"
  end
end
