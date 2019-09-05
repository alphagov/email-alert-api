class FindExactMatch
  def initialize(query_field: :tags, scope: SubscriberList)
    raise ArgumentError.new("query_field must be `:tags` or `:links`") unless %i{tags links}.include?(query_field)

    @query_field = query_field.to_sym
    @scope = scope
  end

  def call(query)
    return unless query.present?

    digest = SubscriberList::HashDigest.generate(query)

    if query_field == :tags
      scope.find_by_tags_digest(digest)
    elsif query_field == :links
      scope.find_by_links_digest(digest)
    end
  end

private

  attr_reader :scope, :query_field
end
