class SearchSubscriberListByTags
  def initialize(repo:, context:, tags:)
    @repo = repo
    @context = context
    @tags = tags
  end

  def call
    context.success(subscriber_list: subscriber_list)
  end

private

  attr_reader(
    :repo,
    :context,
    :tags,
  )

  def subscriber_list
    repo.find_by_tags(tags).first
  end
end
