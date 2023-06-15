class BadListSubscriptionsMigrator
  attr_reader :prefix

  def initialize(prefix)
    @prefix = prefix
  end

  def bad_lists
    subscriber_lists - valid_links_based_lists?(subscriber_lists)
  end

  def output_message
    ids = bad_lists.pluck(:id)
    bad_lists_all_subscriptions_count = ids.map{|id|SubscriberList.find(id).subscriptions.count}
    bad_lists_active_counts = bad_lists.map(&:active_subscriptions_count)
    puts "total subscriber list count for #{prefix}: #{subscriber_lists.count}"
    puts "bad subscriber list count for #{prefix}: #{bad_lists.count}"
    puts "total subscriptions to bad lists: #{bad_lists_all_subscriptions_count.sum}"
    puts "total active subscriptions to bad lists: #{bad_lists_active_counts.sum}"
  end

  def subscriber_list_urls
    @subscriber_list_urls ||= subscriber_lists.pluck(:url).uniq
  end

  def subscriber_lists
    @subscriber_lists ||= SubscriberList.where("url LIKE ?", "%/#{prefix}/%")
  end

  def valid_links_based_lists?(lists)
    lists.select { |list| valid_links_based_list?(list) }
  end

  def valid_links_based_list?(list)
    list.content_id.nil? && has_links_or_tags(list)
  end

  def has_links_or_tags(list)
    list.links.present? || list.tags.present?
  end
end
