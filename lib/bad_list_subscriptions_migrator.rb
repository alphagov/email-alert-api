class BadListSubscriptionsMigrator
  include AllTaxonomyTopics

  def process_all_lists
    subscriber_list_urls.each do |url|
      candidate_lists = SubscriberList.where(url:)
      move_users_from_bad_lists_to_good_list(candidate_lists)
    end
  end

  def bad_lists
    subscriber_lists - valid_links_based_lists?(subscriber_lists)
  end

private

  def subscriber_list_urls
    @subscriber_list_urls ||= subscriber_lists.pluck(:url).uniq
  end

  def subscriber_lists
    taxonomy_topic_urls.flat_map do |taxon_url|
      SubscriberList.where(url: taxon_url)
    end
  end

  def move_users_from_bad_lists_to_good_list(lists)
    good_lists = valid_links_based_lists?(lists)
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