class SubscriberListQuery
  def initialize(query_field: :tags)
    @query_field = query_field
  end

  # Find all lists in which all the links present have at least one match in the
  # supplied list of links. Note - does not require that all the links supplied
  # have any matches.
  def where_all_links_match_at_least_one_value_in(query_hash)
    return [] unless query_hash.present?
    subscriber_lists_with_keys_overlapping(query_hash).select do |subscriber_list|
      subscriber_list.send(@query_field).all? do |descriptor, array_of_values|
        (Array(query_hash[descriptor]) & array_of_values).count > 0
      end
    end
  end

  def at_least_one_topic_value_matches(value)
    subscriber_lists_with_key(:topics).each_with_object([]) do |subscriber_list, results|
      if subscriber_list.send(@query_field)[:topics].include?(value)
        results << subscriber_list
      end
    end
  end

  def find_exact_match_with(query_hash)
    return [] unless query_hash.present?
    subscriber_lists_with_all_matching_keys(query_hash).select do |list|
      list.send(@query_field).all? do |descriptor, array_of_values|
        next if query_hash[descriptor].nil?
        query_hash[descriptor].sort == array_of_values.sort
      end
    end
  end

private
  # Return all SubscriberLists which are marked with any of the same link types
  # as those requested.  For example, if `links` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have any "topics" or "organisations"
  # links.
  def subscriber_lists_with_keys_overlapping(query_hash)
    # This uses the `&&` hstore operator, which returns true if the left and
    # right operand have any overlapping elements
    SubscriberList.where(
      "Array[:keys] && akeys(#{@query_field})", keys: query_hash.keys
    )
  end

  # Return all SubscriberLists which are marked with all of the same link types
  # as those requested.  For example, if `links` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have any "topics" AND "organisations"
  # links.
  def subscriber_lists_with_all_matching_keys(query_hash)
    # This uses the `?&` hstore operator, which returns true only if the hstore
    # contains all the specified keys.
    SubscriberList.where("#{@query_field} ?& Array[:keys]", keys: query_hash.keys)
  end

  def subscriber_lists_with_key(key)
    # This uses the `?` hstore operator, which returns true only if the hstore
    # contains the specified key.
    SubscriberList.where("tags ? :key", key: key)
  end
end
