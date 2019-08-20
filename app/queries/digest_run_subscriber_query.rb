class DigestRunSubscriberQuery
  def self.call(digest_run:)
    content_changes_exist =
      SubscriberList
        .joins(matched_content_changes: :content_change)
        .where("subscriptions.subscriber_list_id = subscriber_lists.id")
        .where("content_changes.created_at >= ?", digest_run.starts_at)
        .where("content_changes.created_at < ?", digest_run.ends_at)
        .arel
        .exists

    messages_exist =
      SubscriberList
        .joins(matched_messages: :message)
        .where("subscriptions.subscriber_list_id = subscriber_lists.id")
        .where("messages.created_at >= ?", digest_run.starts_at)
        .where("messages.created_at < ?", digest_run.ends_at)
        .arel
        .exists

    scope = Subscriber.joins(:active_subscriptions)
                      .where("subscriptions.frequency": digest_run.range)

    scope.where(content_changes_exist)
         .or(scope.where(messages_exist))
         .distinct
  end
end
