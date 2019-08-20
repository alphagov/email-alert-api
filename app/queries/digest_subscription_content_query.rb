class DigestSubscriptionContentQuery
  Result = Struct.new(:subscription_id, :subscriber_list_title, :content)

  def initialize(subscriber, digest_run)
    @subscriber = subscriber
    @digest_run = digest_run
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    build_results(fetch_content_changes, fetch_messages)
  end

  private_class_method :new

private

  attr_reader :subscriber, :digest_run

  def build_results(content_changes, messages)
    result_data = content_changes.each_with_object({}) do |record, memo|
      id = record[:subscription_id]
      memo[id] ||= { subscriber_list_title: record[:subscriber_list_title] }
      memo[id][:content_changes] = Array(memo[id][:content_changes]) << record
    end

    result_data = messages.each_with_object(result_data) do |record, memo|
      id = record[:subscription_id]
      memo[id] ||= { subscriber_list_title: record[:subscriber_list_title] }
      memo[id][:messages] = Array(memo[id][:messages]) << record
    end

    result_data.map do |key, value|
      content = value.fetch(:content_changes, []) + value.fetch(:messages, [])
      Result.new(key, value[:subscriber_list_title], content.sort_by(&:created_at))
    end
  end

  def fetch_content_changes
    ContentChange
      .select("content_changes.*", "subscriptions.id AS subscription_id", "subscriber_lists.title AS subscriber_list_title")
      .joins(matched_content_changes: { subscriber_list: { subscriptions: :subscriber } })
      .where(subscribers: { id: subscriber.id })
      .where(subscriptions: { frequency: Subscription.frequencies[digest_run.range] })
      .where("content_changes.created_at >= ?", digest_run.starts_at)
      .where("content_changes.created_at < ?", digest_run.ends_at)
      .merge(Subscription.active)
      .order("subscriber_list_title ASC", "content_changes.created_at ASC")
      .uniq(&:content_id)
  end

  def fetch_messages
    Message
      .select("messages.*", "subscriptions.id AS subscription_id", "subscriber_lists.title AS subscriber_list_title")
      .joins(matched_messages: { subscriber_list: { subscriptions: :subscriber } })
      .where(subscribers: { id: subscriber.id })
      .where(subscriptions: { frequency: Subscription.frequencies[digest_run.range] })
      .where("messages.created_at >= ?", digest_run.starts_at)
      .where("messages.created_at < ?", digest_run.ends_at)
      .merge(Subscription.active)
      .order("subscriber_list_title ASC", "messages.created_at ASC")
      .uniq(&:id)
  end
end
