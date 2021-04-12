class DigestItemsQuery
  Result = Struct.new(:subscription, :content)

  def initialize(subscriber, digest_run)
    @subscriber = subscriber
    @digest_run = digest_run
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    subscriptions.filter_map do |subscription|
      content = content_changes[subscription.id].to_a
      content += messages[subscription.id].to_a

      next unless content.any?

      content = content.sort_by(&:created_at)
      Result.new(subscription, content)
    end
  end

  private_class_method :new

private

  attr_reader :subscriber, :digest_run

  def content_changes
    @content_changes ||= ContentChange
      .select("content_changes.*, subscriptions.id AS subscription_id")
      .joins(matched_content_changes: { subscriber_list: :subscriptions })
      .where(subscriptions: { id: subscriptions })
      .where("content_changes.created_at >= ?", digest_run.starts_at)
      .where("content_changes.created_at < ?", digest_run.ends_at)
      .order(created_at: :desc)
      .uniq { |content| [content.content_id, content.subscription_id] }
      .group_by(&:subscription_id)
  end

  def messages
    @messages ||= Message
      .select("messages.*, subscriptions.id AS subscription_id")
      .joins(matched_messages: { subscriber_list: :subscriptions })
      .where(subscriptions: { id: subscriptions })
      .where("messages.created_at >= ?", digest_run.starts_at)
      .where("messages.created_at < ?", digest_run.ends_at)
      .uniq(&:id)
      .group_by(&:subscription_id)
  end

  def subscriptions
    @subscriptions ||= subscriber
      .subscriptions
      .active
      .includes(:subscriber_list)
      .where(frequency: Subscription.frequencies[digest_run.range])
  end
end
