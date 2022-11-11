class SubscriberListQuery
  def initialize(content_id:, tags:, links:, document_type:, email_document_supertype:, government_document_supertype:)
    @content_id = content_id
    @tags = tags.symbolize_keys
    @links = links.deep_symbolize_keys
    @document_type = document_type
    @email_document_supertype = email_document_supertype
    @government_document_supertype = government_document_supertype
  end

  def lists
    @lists ||= (
      lists_matched_on_links +
      lists_matched_on_tags +
      lists_matched_without_links_or_tags +
      lists_matched_on_document_collection_id
    ).uniq(&:id)
  end

private

  def lists_matched_on_tags(content_id = @content_id)
    MatchedForNotification.new(query_field: :tags, scope: base_scope(content_id)).call(@tags)
  end

  def lists_matched_on_links(content_id = @content_id)
    MatchedForNotification.new(query_field: :links, scope: base_scope(content_id)).call(@links)
  end

  def lists_matched_without_links_or_tags(content_id = @content_id)
    FindWithoutLinksAndTags.new(scope: base_scope(content_id)).call
  end

  def lists_matched_on_document_collection_id
    return [] unless document_collection_ids

    document_collection_ids.flat_map do |id|
      lists_matched_on_tags(id) +
        lists_matched_on_links(id) +
        lists_matched_without_links_or_tags(id)
    end
  end

  def document_collection_ids
    @links[:document_collections].presence
  end

  def base_scope(content_id)
    SubscriberList
      .where(content_id: [nil, content_id])
      .where(document_type: ["", @document_type])
      .where(email_document_supertype: ["", @email_document_supertype])
      .where(government_document_supertype: ["", @government_document_supertype])
  end
end
