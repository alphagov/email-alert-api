class FindWithoutLinksAndTagsAndContentId
  def initialize(scope: SubscriberList)
    @scope = scope
  end

  def call
    @scope.where("tags::text = '{}'::text AND links::text = '{}'::text AND content_id::text IS null")
  end
end
