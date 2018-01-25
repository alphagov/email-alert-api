class DigestSubscriberQuery
  def self.call(digest_run:)
    Subscriber
      .joins(subscriptions: { subscriber_list: { matched_content_changes: :content_change } })
      .where("content_changes.created_at >= ?", digest_run.starts_at)
      .where("content_changes.created_at < ?", digest_run.ends_at)
      .where("subscriptions.frequency": digest_run.range)
  end
end
