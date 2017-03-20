class SubscriberListQuery

  def initialize(tags_hash, links_hash, document_type)
    @tags_hash = tags_hash
    @links_hash = links_hash
    @document_type = document_type
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
    @lists_matched_on_tags ||=
      MatchedForNotification.new(query_field: :tags, scope: base_scope).call(@tags_hash)
  end

  def lists_matched_on_links
    @lists_matched_on_links ||=
      MatchedForNotification.new(query_field: :links, scope: base_scope).call(@links_hash)
  end

  def lists_matched_on_document_type_only
    @lists_matched_on_document_type_only ||= WhereOnlyDocumentTypeMatches.new.call(@document_type)
  end

  def base_scope
    SubscriberList
      .where(document_type: ['', @document_type])
  end
end
