class BadListDeleter
  VALID_PREFIXES = %w[
    topic
    organisations
    government/people
    government/ministers
    government/topical-events
    service-manual
    service-manual/service-standard
  ].freeze

  attr_reader :prefix

  def initialize(prefix)
    @prefix = prefix
  end

  def process_all_lists
    message = "Bad list deletion not possible for the provided prefix"
    raise message unless valid_prefix?

    bad_lists.each do |bad_list|
      if bad_list.subscriptions.active.any?
        next
      end

      bad_list.destroy!
    end
  end

  def bad_lists
    subscriber_lists - valid_links_based_lists?(subscriber_lists)
  end

private

  def valid_prefix?
    VALID_PREFIXES.include?(prefix)
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
