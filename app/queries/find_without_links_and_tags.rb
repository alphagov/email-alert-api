class FindWithoutLinksAndTags
  def initialize(scope: SubscriberList)
    @scope = scope
  end

  def call
    @scope.where("tags::text = '{}'::text AND links::text = '{}'::text")
  end
end

