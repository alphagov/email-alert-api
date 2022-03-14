class Reports::SinglePageNotificationsReport
  attr_reader :report_time

  def initialize(limit = 25)
    @limit = limit.to_i
    @report_time = Time.zone.now
  end

  def call
    [
      report_on_total_lists,
      *report_on_top_lists,
    ]
  end

private

  attr_reader :limit

  def report_on_total_lists
    "There are #{subscriber_list_with_content_ids.count} subscription lists with content_ids as of #{report_time}\n"
  end

  def report_on_top_lists
    [
      "Top #{limit} lists by active subscriber count are:\n",
      *subscriber_lists_by_active_sub_count,
    ]
  end

  def subscriber_lists_by_active_sub_count
    subscriber_list_with_content_ids.map { |list| gather_data(list) }
                                    .sort_by { |list| list[:active_subscribers] }
                                    .last(limit)
                                    .map { |list| present(list) }
                                    .reverse
                                    .flatten
  end

  def subscriber_list_with_content_ids
    @subscriber_list_with_content_ids ||= SubscriberList.where.not(content_id: nil)
  end

  def gather_data(subscriber_list)
    {
      title: subscriber_list.title,
      url: subscriber_list.url,
      active_subscribers: active_subscribers(subscriber_list),
    }
  end

  def present(subscriber_list)
    <<~TEXT
      Title: #{subscriber_list[:title]}
      URL: #{subscriber_list[:url]}
      Has #{subscriber_list[:active_subscribers]} Active Subscribers
    TEXT
  end

  def active_subscribers(subscriber_list)
    subscriber_list.subscriptions
      .active_on(@report_time)
      .count
  end
end
