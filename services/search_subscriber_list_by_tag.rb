class SearchSubscriberListByTags
  def initialize(repo:, context:, tags:)
    @repo = repo
    @context = context
    @tags = tags
  end

  def call
    if subscriber_list
      context.success(subscriber_list: subscriber_list)
    else
      context.not_found(error: "A subscriber list with those tags does not exist")
    end
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
