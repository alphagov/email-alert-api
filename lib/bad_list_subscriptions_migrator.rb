class BadListSubscriptionsMigrator
  VALID_PREFIXES = %w[topic].freeze

  attr_reader :prefix

  def initialize(prefix)
    @prefix = prefix
  end

  def process_all_lists
    message = "Subscription migration not possible for the provided prefix"
    raise message unless valid_prefix?

    subscriber_list_urls.each do |url|
      candidate_lists = SubscriberList.where(url:)
      move_users_from_bad_lists_to_good_list(candidate_lists)
    end
  end

private

  def valid_prefix?
    VALID_PREFIXES.include?(prefix)
  end

  def subscriber_list_urls
    @subscriber_list_urls ||= subscriber_lists.pluck(:url).uniq
  end

  def subscriber_lists
    @subscriber_lists ||= SubscriberList.where("url LIKE ?", "%/#{prefix}/%")
  end

  def move_users_from_bad_lists_to_good_list(lists)
    good_lists = lists.select { |list| valid_links_based_list?(list) }
    bad_lists = lists - good_lists

    good_list = good_lists.first

    if good_list && good_list.active_subscriptions_count.positive?
      with_active_subscriptions(bad_lists).each do |bad_list|
        SubscriberListMover.new(from_slug: bad_list.slug, to_slug: good_list.slug).call
      end
    end
  end

  def with_active_subscriptions(lists)
    lists.select { |list| list.active_subscriptions_count.positive? }
  end

  def valid_links_based_list?(list)
    list.content_id.nil? && has_links_or_tags(list)
  end

  def has_links_or_tags(list)
    list.links.present? || list.tags.present?
  end
end
