class SubscriberListQuery
  def initialize(query_field: :tags)
    raise ArgumentError.new("query_field must be `:tags`, `:links`, or `:neither`") unless %i{tags links neither}.include?(query_field)

    @query_field = query_field.to_sym
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

  def where_only_document_type_matches(document_type)
    subscriber_lists_without_tags_or_links.where(document_type: document_type)
  end

  def at_least_one_topic_value_matches(value)
    subscriber_lists_with_key(:topics).each_with_object([]) do |subscriber_list, results|
      if subscriber_list.send(@query_field)[:topics].include?(value)
        results << subscriber_list
      end
    end
  end

  def find_exact_match_with(query_hash, document_type)
    return [] unless query_hash.present?

    subscriber_lists = subscriber_lists_with_all_matching_keys(query_hash)
    subscriber_lists = subscriber_lists.where(document_type: document_type)

    subscriber_lists.select do |list|
      list.send(@query_field).all? do |descriptor, array_of_values|
        next if query_hash[descriptor].nil?
        query_hash[descriptor].sort == array_of_values.sort
      end
    end
  end

  def subscriber_lists_with_key(key)
    # This uses the `->` JSON operator to select lists only if the field's keys
    # contain the specified key.
    SubscriberList.where("(#{@query_field} -> :key) IS NOT NULL", key: key)
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
    # This uses the `&&` array operator, which returns true if the left and
    # right operand have any overlapping elements
    SubscriberList.where("ARRAY(SELECT json_object_keys(#{@query_field})) && Array[:keys]",
      keys: query_hash.keys,
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
    # This uses array equality to check if the JSON object
    # contains all the specified keys.
    SubscriberList.where("ARRAY(SELECT json_object_keys(#{@query_field})) = Array[:keys]",
      keys: query_hash.keys,
    )
  end

  def subscriber_lists_without_tags_or_links
    SubscriberList.where("tags::text = '{}'::text AND links::text = '{}'::text")
  end
end
