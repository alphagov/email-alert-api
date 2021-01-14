class Reports::PotentiallyDeadListsReport
  def call
    distinct_list_sql = Arel.sql("distinct subscriber_list_id")

    recent_subscriptions = Subscription
      .where("created_at > ?", 1.year.ago)
      .pluck(distinct_list_sql)

    all_changes = MatchedContentChange.pluck(distinct_list_sql) +
      MatchedMessage.pluck(distinct_list_sql)

    potentially_dead_slugs = SubscriberList
      .where(id: Subscription.active.pluck(distinct_list_sql))
      .where.not(id: recent_subscriptions | all_changes)
      .pluck(:slug)

    Reports::SubscriberListsReport.new(
      Date.yesterday.to_s, slugs: potentially_dead_slugs.join(",")
    ).call
  end
end
