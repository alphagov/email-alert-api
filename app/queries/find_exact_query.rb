class FindExactQuery
  class InvalidFindCriteria < StandardError; end

  def initialize(tags:, links:, document_type:, email_document_supertype:, government_document_supertype:)
    @tags = tags.symbolize_keys
    @links = links.symbolize_keys
    @document_type = document_type
    @email_document_supertype = email_document_supertype
    @government_document_supertype = government_document_supertype
  end

  def exact_match
    return find_exact(:links, @links) if @links.any?
    return find_exact(:tags, @tags) if @tags.any?
    FindWithoutLinksAndTags.new(scope: base_scope).call.first
  end

private

  def base_scope
    SubscriberList
      .where(document_type: @document_type)
      .where(email_document_supertype: @email_document_supertype)
      .where(government_document_supertype: @government_document_supertype)
  end

  def find_exact(query_field, query)
    FindExactMatch.new(query_field: query_field, scope: base_scope).call(query).first
  end
end
