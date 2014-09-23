class UniqueTagSetFilter
  def initialize(repo:, service:, context:, tags:)
    @repo = repo
    @service = service
    @context = context
    @tags = tags
  end

  def call
    if repo.find_by_tags(tags).empty?
      service.call(context)
    else
      context.unprocessible(error: error_message)
    end
  end
private

  attr_reader(
    :repo,
    :service,
    :context,
    :tags,
  )

  def error_message
    "A topic with that tag set already exists"
  end
end
