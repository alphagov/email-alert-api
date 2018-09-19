class UnpublishingReport
  def initialize(start_date, end_date)
    @start_date = Time.parse(start_date)
    @end_date = Time.parse(end_date)
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    puts "Unpublishing activity between #{start_date} and #{end_date}"

    subscriptions_info = subscriber_lists_with_subscribers(unpublished_subscriptions)
    subscription_count_per_subscriber_list(subscriptions_info)
  end

private

  attr_reader :start_date, :end_date

  def unpublished_subscriptions
    Subscription.where(ended_reason: "unpublished")
                .where(ended_at: start_date..end_date)
  end

  def subscriber_lists_with_subscribers(unpublished_subscriptions)
    hash_array = Hash.new do |hash, key|
      hash[key] = []
    end

    unpublished_subscriptions
      .pluck(:subscriber_list_id, :subscriber_id)
      .each_with_object(hash_array) { |(key, value), result| result[key] << value }
  end

  def subscription_count_per_subscriber_list(subscriptions_info)
    subscriptions_info.each do |subscriber_list_id, subscription_ids|
      title = SubscriberList.find(subscriber_list_id).title
      subscriptions_count = subscription_ids.count

      puts "'#{title}' has been unpublished ending #{subscriptions_count} subscriptions"
    end
  end
end
