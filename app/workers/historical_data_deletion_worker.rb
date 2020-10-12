class HistoricalDataDeletionWorker < ApplicationWorker
  def perform
    # cascades matched content changes
    ContentChange.where("created_at < ?", retention_period).delete_all

    # cascades matched messages
    Message.where("created_at < ?", retention_period).delete_all

    # cascades digest run subscribers
    DigestRun.where("created_at < ?", retention_period).delete_all

    # deleting subscriptions must be done before deleting subscriber lists or subscribers
    Subscription.where("ended_at < ?", retention_period).delete_all

    empty_subscriber_lists.delete_all

    # restricts deletion if emails are present
    Subscriber.where("deactivated_at < ?", retention_period).delete_all
  end

private

  def retention_period
    @retention_period ||= 1.year.ago
  end

  def empty_subscriber_lists
    SubscriberList.left_outer_joins(:subscriptions)
                  .where("subscriber_lists.created_at < ?", retention_period)
                  .where("subscriptions.id": nil)
  end
end
