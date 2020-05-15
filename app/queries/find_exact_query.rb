class FindExactQuery
  class InvalidFindCriteria < StandardError; end

  def initialize(
    tags:,
    links:,
    document_type:,
    email_document_supertype:,
    government_document_supertype:,
    slug: nil
  )
    @tags = tags.deep_symbolize_keys
    @links = links.deep_symbolize_keys
    @document_type = document_type
    @email_document_supertype = email_document_supertype
    @government_document_supertype = government_document_supertype
    @slug = slug
  end

  def exact_match
    return find_exact(:links, @links) if @links.any?
    return find_exact(:tags, @tags) if @tags.any?

    FindWithoutLinksAndTags.new(scope: base_scope).call.first
  end

private

  def base_scope
    @base_scope ||= begin
      scope = SubscriberList
        .where(document_type: @document_type)
        .where(email_document_supertype: @email_document_supertype)
        .where(government_document_supertype: @government_document_supertype)
      scope = scope.where(slug: @slug) if @slug.present?
      scope
    end
  end

  def find_exact(query_field, query)
    raise ArgumentError, "query_field must be `:tags` or `:links`" unless %i[tags links].include?(query_field)

    return if query.blank?

    digest = HashDigest.new(query).generate

    if query_field == :tags
      base_scope.find_by_tags_digest(digest)
    elsif query_field == :links
      base_scope.find_by_links_digest(digest)
    end
  end
end
