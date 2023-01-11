class FindExactQuery
  class InvalidFindCriteria < StandardError; end

  def initialize(
    content_id:,
    tags:,
    links:,
    document_type:,
    email_document_supertype:,
    government_document_supertype:,
    slug: nil
  )
    @content_id = content_id.presence
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
    return find_exact(:content_id, @content_id) if @content_id.presence

    FindWithoutLinksAndTagsAndContentId.new(scope: document_type_scope).call.first
  end

private

  def base_scope
    @base_scope ||= begin
      scope = document_type_scope
        .where(content_id: @content_id)
      scope = scope.where(slug: @slug) if @slug.present?
      scope
    end
  end

  def document_type_scope
    SubscriberList
      .where(document_type: @document_type)
      .where(email_document_supertype: @email_document_supertype)
      .where(government_document_supertype: @government_document_supertype)
  end

  def find_exact(query_field, query)
    raise ArgumentError, "query_field must be `:tags` or `:links` or `:content_id`" unless %i[tags links content_id].include?(query_field)

    return if query.blank?

    case query_field
    when :tags
      base_scope.find_by_tags_digest(hash_digest(query))
    when :links
      base_scope.find_by_links_digest(hash_digest(query))
    when :content_id
      base_scope.first
    end
  end

  def hash_digest(query)
    HashDigest.new(query).generate
  end
end
