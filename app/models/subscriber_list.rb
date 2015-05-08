require 'json'

class SubscriberList < ActiveRecord::Base
  self.include_root_in_json = true

  # Find all lists in which all the tags present have at least one match in the
  # supplied list of tags.  Note - does not require that all the tags supplied
  # have any matches.
  def self.with_at_least_one_tag_of_each_type(tags:)
    lists_with_matching_keys(tags).select do |list|
      list.tags.all? do |tag_type, tag_array|
        (tags[tag_type] & tag_array).count > 0
      end
    end
  end

  def self.with_at_least_one_topic_value(value)
    lists_with_key(:topics).each_with_object([]) do |subscription_list, results|
      if subscription_list.tags[:topics].include?(value)
        results << subscription_list
      end
    end
  end

  def self.where_tags_equal(tags)
    lists_with_all_matching_keys(tags).select do |list|
      list.tags.all? do |tag_type, tag_array|
        next if tags[tag_type].nil?
        tags[tag_type].sort == tag_array.sort
      end
    end
  end

  def tags
    @_tags ||= super.inject({}) do |hash, (tag_type, tags_json)|
      hash.merge(tag_type.to_sym => JSON.parse(tags_json))
    end
  end

  def reload
    @_tags = nil
    super
  end

  def subscription_url
    gov_delivery_config.fetch(:protocol) +
    "://" +
    gov_delivery_config.fetch(:public_hostname) +
    "/accounts/" +
    gov_delivery_config.fetch(:account_code) +
    "/subscriber/new?topic_id=" +
    self.gov_delivery_id
  end

  def to_json
    super(methods: :subscription_url)
  end

private

  def gov_delivery_config
    EmailAlertAPI.config.gov_delivery
  end

  # Return all SubscriberLists which are marked with any of the same tag types
  # as those requested.  For example, if `tags` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have any "topics" or "organisations"
  # tags.
  def self.lists_with_matching_keys(tags)
    # This uses the `@>` hstore operator, which returns true if and only
    # if its left operand contains its right one.
    where("Array[:tag_keys] @> akeys(tags)", tag_keys: tags.keys)
  end

  # Return all SubscriberLists which are marked with all of the same tag types
  # as those requested.  For example, if `tags` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have any "topics" AND "organisations"
  # tags.
  def self.lists_with_all_matching_keys(tags)
    # This uses the `?&` hstore operator, which returns true only if the hstore
    # contains all the specified keys.
    where("tags ?& Array[:tag_keys]", tag_keys: tags.keys)
  end

  def self.lists_with_key(key)
    # This uses the `?` hstore operator, which returns true only if the hstore
    # contains the specified key.
    where("tags ? :key", key: key)
  end
end
