class FindExactQuery
  class InvalidFindCriteria < StandardError; end

  def initialize(
    tags:,
    links:,
    document_type:,
    email_document_supertype:,
    government_document_supertype:,
    slug: nil,
    content_purpose_supergroup:,
    reject_content_purpose_supergroup:
  )
    @tags = tags.deep_symbolize_keys
    @links = links.deep_symbolize_keys
    @document_type = document_type
    @email_document_supertype = email_document_supertype
    @government_document_supertype = government_document_supertype
    @content_purpose_supergroup = content_purpose_supergroup
    @reject_content_purpose_supergroup = reject_content_purpose_supergroup
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
        .where(content_purpose_supergroup: @content_purpose_supergroup)
        .where(reject_content_purpose_supergroup: @reject_content_purpose_supergroup)
      scope = scope.where(slug: @slug) if @slug.present?
      scope
    end
  end

  def find_exact(query_field, query)
    FindExactMatch.new(query_field: query_field, scope: base_scope).call(query).first
  end
end
