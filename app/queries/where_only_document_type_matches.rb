class WhereOnlyDocumentTypeMatches
  def call(document_type)
    subscriber_lists_without_tags_or_links.where(document_type: document_type)
  end

private

  def subscriber_lists_without_tags_or_links
    SubscriberList.where("tags::text = '{}'::text AND links::text = '{}'::text")
  end
end
