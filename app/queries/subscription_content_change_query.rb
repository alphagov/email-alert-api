class SubscriptionContentChangeQuery
  def initialize(subscriber:, digest_run:)
    @subscriber = subscriber
    @digest_run = digest_run
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    present
  end

  private_class_method :new

private

  attr_reader :subscriber, :digest_run

  Result = Struct.new(:subscription_id, :subscriber_list_title, :content_changes)

  def present
    grouped_content_changes.map do |(subscription_id, subscriber_list_title), content_changes|
      Result.new(
        subscription_id,
        subscriber_list_title,
        content_changes,
      )
    end
  end

  def grouped_content_changes
    content_changes.group_by do |record|
      [record["subscription_id"], record["subscriber_list_title"]]
    end
  end

  def content_changes
    ContentChange
      .select("content_changes.*", "subscriptions.id AS subscription_id", "subscriber_lists.title AS subscriber_list_title")
      .joins(matched_content_changes: { subscriber_list: { subscriptions: :subscriber } })
      .where(subscribers: { id: subscriber.id })
      .where(subscriptions: { frequency: Subscription.frequencies[digest_run.range] })
      .where("content_changes.created_at >= ?", digest_run.starts_at)
      .where("content_changes.created_at < ?", digest_run.ends_at)
      .merge(Subscription.active)
      .order("subscriber_list_title ASC", "content_changes.title ASC")
  end
end
