class SubscriberListQuery
  def initialize(query_field: :tags)
    @query_field = query_field
  end

  # Find all lists in which all the tags present have at least one match in the
  # supplied list of tags.  Note - does not require that all the tags supplied
  # have any matches.
  def self.at_least_one_tag_of_each_type(tags:)
    lists_with_matching_keys(tags).select do |list|
      list.tags.all? do |tag_type, tag_array|
        (tags[tag_type] & tag_array).count > 0
      end
    end
  end

  def self.at_least_one_topic_value(value)
    lists_with_key(:topics).each_with_object([]) do |subscription_list, results|
      if subscription_list.tags[:topics].include?(value)
        results << subscription_list
      end
    end
  end

  def find_exact_match_with(metadata_hash)
    subscriber_lists_with_all_matching_keys(metadata_hash).select do |list|
      list.send(@query_field).all? do |descriptor, array_of_values|
        next if metadata_hash[descriptor].nil?
        metadata_hash[descriptor].sort == array_of_values.sort
      end
    end
  end

private
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
    SubscriberList.where("Array[:tag_keys] @> akeys(tags)", tag_keys: tags.keys)
  end

  # Return all SubscriberLists which are marked with all of the same tag types
  # as those requested.  For example, if `tags` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have any "topics" AND "organisations"
  # tags.
  def subscriber_lists_with_all_matching_keys(metadata_hash)
    # This uses the `?&` hstore operator, which returns true only if the hstore
    # contains all the specified keys.
    SubscriberList.where("#{@query_field} ?& Array[:keys]", keys: metadata_hash.keys)
  end

  def self.lists_with_key(key)
    # This uses the `?` hstore operator, which returns true only if the hstore
    # contains the specified key.
    SubscriberList.where("tags ? :key", key: key)
  end
end
