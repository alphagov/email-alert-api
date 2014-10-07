class SearchSubscriberListByTags
  def initialize(repo:, responder:, tags:)
    @repo = repo
    @responder = responder
    @tags = tags
  end

  def call
    if subscriber_list
      responder.success(subscriber_list: subscriber_list)
    else
      responder.not_found(error: "A subscriber list with those tags does not exist")
    end
  end

private

  attr_reader(
    :repo,
    :responder,
    :tags,
  )

  def subscriber_list
    repo.find_by_tags(tags.to_h).first
  end
end
