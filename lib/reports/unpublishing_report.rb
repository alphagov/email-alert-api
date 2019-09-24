module Reports
  class UnpublishingReport
    def initialize(start_date, end_date)
      @start_date = Time.parse(start_date)
      @end_date = Time.parse(end_date)
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      subscriptions_info = subscriber_lists_with_subscribers(unpublished_subscriptions)
      generate_report(subscriptions_info)
    end

  private

    attr_reader :start_date, :end_date

    def unpublished_subscriptions
      Subscription.where(ended_reason: "unpublished", ended_at: start_date..end_date)
    end

    def subscriber_lists_with_subscribers(unpublished_subscriptions)
      hash_array = Hash.new { |hash, key| hash[key] = [] }

      unpublished_subscriptions
        .pluck(:subscriber_list_id, :subscriber_id)
        .each_with_object(hash_array) { |(key, value), result| result[key] << value }
    end

    def generate_report(subscriptions_info)
      puts "Unpublishing activity between #{start_date.strftime('%Y-%m-%d %H:%M:%S')} and #{end_date.strftime('%Y-%m-%d %H:%M:%S')}"
      puts ""

      subscriptions_info.each do |subscriber_list_id, subscriber_ids|
        title = SubscriberList.find(subscriber_list_id).title

        puts "'#{title}' has been unpublished ending #{subscriber_ids.count} subscriptions"
        puts ""

        new_subscriptions(subscriber_ids)

        puts "-------------------------------------------"
      end
    end

    def new_subscriptions(subscriber_ids)
      subscriber_list_ids = []
      Subscriber.where(id: subscriber_ids).each do |subscriber|
        subscriber_list_ids.concat(
          subscriber.subscriptions
            .where(ended_at: nil)
            .where("created_at > ?", start_date)
            .pluck(:subscriber_list_id),
        )
      end

      new_subscriptions_with_count(subscriber_list_ids)
    end

    def new_subscriptions_with_count(subscriber_list_ids)
      grouped_ids = subscriber_list_ids.group_by { |subscriber_list| subscriber_list }

      grouped_ids.each do |id, values|
        puts "- #{values.count} subscribers have now subscribed to '#{SubscriberList.find(id).title}'"
      end
    end
  end
end
