class SubscriberListQuery
  def initialize(query_field: :tags)
    raise ArgumentError.new("query_field must be `:tags`, `:links`, or `:neither`") unless %i{tags links neither}.include?(query_field)

    @query_field = query_field.to_sym
  end

  # Find all lists in which at least one match in the supplied list.
  # Note - does not require that all the supplied hash is matched.
  def with_one_matching_value_for_each_key(content_item_tags_or_links)
    return [] unless content_item_tags_or_links.present?

    content_item_tags_or_links = content_item_tags_or_links.stringify_keys

    only_contains_keys(content_item_tags_or_links.keys).select do |subscriber_list|
      subscriber_list_tags_or_links = subscriber_list[@query_field]

      subscriber_list_tags_or_links.keys.all? do |key|
        (
          content_item_tags_or_links[key] & subscriber_list_tags_or_links[key]
        ).any?
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
  # Return all SubscriberLists which have a subscet of keys from those requested.
  # For example, if `links` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have only "topics" and/or "organisations"
  # links, but not those with "topics" and "policies"
  def only_contains_keys(keys)
    # This uses the <@` array operator, which returns true if the all the items in the left
    # side array are contained in the right side array
    SubscriberList
      .where("#{@query_field}::text != '{}'")
      .where("ARRAY(SELECT json_object_keys(#{@query_field})) <@ Array[:keys]",
        keys: keys,
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
