class HistoricalDataDeletionWorker < ApplicationWorker
  def perform
    # cascades matched content changes
    delete_and_log("content changes") { ContentChange.where("created_at < ?", max_retention_period) }

    # cascades matched messages
    delete_and_log("messages") { Message.where("created_at < ?", max_retention_period) }

    # cascades digest run subscribers
    delete_and_log("digest runs") { DigestRun.where("created_at < ?", max_retention_period) }

    # deleting subscriptions must be done before deleting subscriber lists or subscribers
    delete_and_log("subscriptions") { Subscription.where("ended_at < ?", max_retention_period) }

    delete_and_log("subscriber lists") { empty_subscriber_lists }

    # restricts deletion if emails are present
    delete_and_log("subscribers") { Subscriber.where("deactivated_at < ?", max_retention_period) }
  end

private

  def max_retention_period
    @max_retention_period ||= 1.year.ago
  end

  def empty_list_retention_period
    @empty_list_retention_period ||= 7.days.ago
  end

  def delete_and_log(model)
    start_time = Time.zone.now
    deleted_count = yield.delete_all
    seconds = (Time.zone.now - start_time).round(2)

    message = "Deleted #{deleted_count} #{model} in #{seconds} seconds"
    logger.info(message)
  end

  def empty_subscriber_lists
    SubscriberList.left_outer_joins(:subscriptions)
                  .where("subscriber_lists.created_at < ?", empty_list_retention_period)
                  .where("subscriptions.id": nil)
  end
end
