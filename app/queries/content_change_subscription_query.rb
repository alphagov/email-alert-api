class ContentChangeSubscriptionQuery
  def self.call(content_change:)
    Subscription.where(
      subscriber_list: MatchedContentChange.where(content_change: content_change).pluck(:subscriber_list_id)
    ).distinct
  end
end
