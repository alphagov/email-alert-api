class ContentChangeSubscriptionQuery
  def self.call(content_change:)
    Subscription
      .joins(subscriber_list: :matched_content_changes)
      .where(matched_content_changes: { content_change_id: content_change.id })
      .where(frequency: "immediately")
      .distinct
  end
end
