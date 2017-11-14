class SubscriptionMatcher
  def self.call(content_change:)
    Subscription.where(
      subscriber_list: subscribables_for(content_change: content_change)
    ).distinct
  end

  def self.subscribables_for(content_change:)
    SubscriberListQuery.new(
      tags: content_change.tags,
      links: content_change.links,
      document_type: content_change.document_type,
      email_document_supertype: content_change.email_document_supertype,
      government_document_supertype: content_change.government_document_supertype,
    ).lists
  end
end
