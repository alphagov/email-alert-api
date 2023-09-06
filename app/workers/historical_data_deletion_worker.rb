class HistoricalDataDeletionWorker < ApplicationWorker
  def perform
    # cascades matched content changes
    destroy_and_log("content changes") { ContentChange.where("created_at < ?", max_retention_period) }

    # cascades matched messages
    destroy_and_log("messages") { Message.where("created_at < ?", max_retention_period) }

    # cascades digest run subscribers
    destroy_and_log("digest runs") { DigestRun.where("created_at < ?", max_retention_period) }

    # deleting subscriptions must be done before deleting subscriber lists or subscribers
    destroy_and_log("subscriptions") { Subscription.where("ended_at < ?", max_retention_period) }

    destroy_and_log("subscriber lists") { historic_subscriber_lists }

    # restricts deletion if emails are present
    destroy_and_log("subscribers") { historic_subscribers }
  end

private

  def max_retention_period
    @max_retention_period ||= 1.year.ago
  end

  def empty_list_retention_period
    @empty_list_retention_period ||= 7.days.ago
  end

  def destroy_and_log(model)
    start_time = Time.zone.now
    deleted_count = yield.destroy_all
    seconds = (Time.zone.now - start_time).round(2)

    message = "Deleted #{deleted_count} #{model} in #{seconds} seconds"
    logger.info(message)
  end

  def historic_subscriber_lists
    subscriptions_exist = Subscription.not_historical.where(
      "subscriber_lists.id = subscriptions.subscriber_list_id",
    ).arel.exists

    SubscriberList
      .where("created_at < ?", empty_list_retention_period)
      .where.not(subscriptions_exist)
  end

  def historic_subscribers
    subscriptions_exist = Subscription.not_historical.where(
      "subscribers.id = subscriptions.subscriber_id",
    ).arel.exists

    Subscriber
      .where("created_at < ?", max_retention_period)
      .where.not(subscriptions_exist)
  end
end
