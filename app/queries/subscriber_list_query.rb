class SubscriberListQuery
  def initialize(content_id:, tags:, links:, document_type:, email_document_supertype:, government_document_supertype:)
    @content_id = content_id
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
      lists_matched_on_document_type_only +
      lists_matched_on_content_id
    ).uniq(&:id)
  end

private

  def lists_matched_on_tags
    MatchedForNotification.new(query_field: :tags, scope: document_type_scope).call(@tags)
  end

  def lists_matched_on_links
    MatchedForNotification.new(query_field: :links, scope: document_type_scope).call(@links)
  end

  def lists_matched_on_document_type_only
    FindWithoutLinksAndTagsAndContentId.new(scope: document_type_scope).call
  end

  def lists_matched_on_content_id
    SubscriberList.where(content_id: @content_id)
  end

  def document_type_scope
    SubscriberList
      .where(document_type: ["", @document_type])
      .where(email_document_supertype: ["", @email_document_supertype])
      .where(government_document_supertype: ["", @government_document_supertype])
  end
end
