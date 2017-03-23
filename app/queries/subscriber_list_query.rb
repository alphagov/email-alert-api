class SubscriberListQuery
  def initialize(tags:, links:, document_type:, email_document_supertype:, government_document_supertype:)
    @tags = tags.symbolize_keys
    @links = links.symbolize_keys
    @document_type = document_type
    @email_document_supertype = email_document_supertype
    @government_document_supertype = government_document_supertype
  end

  def lists
    @lists ||= (
      lists_matched_on_links +
      lists_matched_on_tags +
      lists_matched_on_document_type_only
    ).uniq { |l| l.id }
  end

private

  def lists_matched_on_tags
    MatchedForNotification.new(query_field: :tags, scope: base_scope).call(@tags)
  end

  def lists_matched_on_links
    MatchedForNotification.new(query_field: :links, scope: base_scope).call(@links)
  end

  def lists_matched_on_document_type_only
    FindWithoutLinksAndTags.new(scope: base_scope).call
  end

  def base_scope
    SubscriberList
      .where(document_type: ['', @document_type])
      .where(email_document_supertype: ['', @email_document_supertype])
      .where(government_document_supertype: ['', @government_document_supertype])
  end
end
